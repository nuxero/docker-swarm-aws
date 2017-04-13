####    IMPORTS
import boto3
import os
from subprocess import run
from subprocess import call
from subprocess import PIPE

####    INITIALIZE VARIABLES
ec2 = boto3.client('ec2')
role = os.environ['ROLE']
current_instance = os.environ['INSTANCE']

####    SOME UTILITIES
def add_tag(tags):
    response_tags = ec2.create_tags(
        Resources=[
            current_instance
        ],
        Tags=tags
    )
    print(response_tags)

def describe_managers(instance_state):
    response = ec2.describe_instances(
        Filters=[
            {
                'Name': 'tag:Name',
                'Values': ['SwarmManager']
            },
            {
                'Name': 'instance-state-name',
                'Values': instance_state
            },
            {
                'Name': 'tag:Init',
                'Values': ['true']
            }
        ]
    )
    return response

####    QUERY MANAGERS
managers_running = describe_managers(['running'])
managers_replaced = describe_managers(['shutting-down','stopped','terminated','stopping'])

instances_count = 0
for mgr in managers_running['Reservations']:
    instances_count += len(mgr['Instances'])
print(instances_count)

replaced_instances_count = 0
replaced_instances = []
for mgr in managers_replaced['Reservations']:
    replaced_instances_count += len(mgr['Instances'])
    for instance in mgr['Instances']:
        replaced_instances.append(instance)
print(replaced_instances_count)

####    INITIALIZE/JOIN CLUSTER
if instances_count > 0 or role == 'worker':
    ####    JOIN CLUSTER
    manager = managers_running['Reservations'][0]['Instances'][0]['PrivateIpAddress'] # any running manager
    call(["echo","'Here I join to the cluster {}'".format(manager)]) # a friendly message for debugging
    token = run(["docker","-H {}:2376".format(manager),"swarm","join-token","-q",role],stdout=PIPE) # get the token
    call(['docker','swarm','join','{}:2377'.format(manager),'--token',token.stdout.decode('utf-8').replace('\n','')]) # join to cluster

    ####    ADD TAGS
    if role == 'manager':
        hostname = run(['hostname'],stdout=PIPE)
        add_tag([{'Key': 'Init','Value': 'true'},{'Key': 'Hostname','Value': hostname.stdout.decode('utf-8').replace('\n','')}])

    ####    CLEAN NODES
    if replaced_instances_count > 0 and role == 'manager':
        ## docker demote node && docker rm node
        for instance in replaced_instances:
            for tag in instance['Tags']:
                if tag['Key'] == 'Hostname':
                    call(["docker","node","demote",tag['Value']])
                    call(["docker","node","rm",tag['Value']])


else:
    ####    INIT CLUSTER
    call(["echo","'Here I init the cluster'"])
    call(["docker","swarm","init"])

    ####    ADD TAGS
    hostname = run(['hostname'],stdout=PIPE)
    add_tag([{'Key': 'Init','Value': 'true'},{'Key': 'Hostname','Value': hostname.stdout.decode('utf-8').replace('\n','')}])
