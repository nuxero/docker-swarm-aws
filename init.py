####    IMPORTS
import os
from subprocess import run
from subprocess import call
from subprocess import PIPE
import boto3

####    INITIALIZE VARIABLES
ec2 = boto3.client('ec2')
role = os.environ['ROLE']
current_instance = os.environ['INSTANCE']

####    SOME UTILITIES
def add_tag(tags):
    response_tags = ec2.create_tags(Resources=[current_instance], Tags=tags)
    print(response_tags)

def describe_nodes(filters):
    response = ec2.describe_instances(Filters=filters)
    return response

def count_nodes(nodes):
    count = 0
    instances_list = []
    for ins in nodes:
        count += len(ins['Instances'])
        for obj in ins['Instances']:
            instances_list.append(obj)
    print(count)
    return count, instances_list

####    QUERY MANAGERS && WORKERS
managers_running = describe_nodes([{'Name': 'tag:Name', 'Values': ['SwarmManager']}, {'Name': 'instance-state-name', 'Values': ['running']}, {'Name': 'tag:Init', 'Values': ['true']}])
managers_replaced = describe_nodes([{'Name': 'tag:Name', 'Values': ['SwarmManager']}, {'Name': 'instance-state-name', 'Values': ['shutting-down', 'stopped', 'terminated', 'stopping']}, {'Name': 'tag:Init', 'Values': ['true']}])
workers_replaced = describe_nodes([{'Name': 'tag:Name', 'Values': ['SwarmWorker']}, {'Name': 'instance-state-name', 'Values': ['shutting-down', 'stopped', 'terminated', 'stopping']}])

instances_count, instances = count_nodes(managers_running['Reservations'])
replaced_instances_count, replaced_instances = count_nodes(managers_replaced['Reservations'])
replaced_workers_count, replaced_workers = count_nodes(workers_replaced['Reservations'])

####    INITIALIZE/JOIN CLUSTER
if instances_count > 0 or role == 'worker':
    ####    JOIN CLUSTER
    manager = instances[0]['PrivateIpAddress'] # any running manager
    call(["echo", "'Here I join to the cluster {}'".format(manager)]) # a friendly message for debugging
    token = run(["docker", "-H {}:2376".format(manager), "swarm", "join-token", "-q", role], stdout=PIPE) # get the token
    call(['docker', 'swarm', 'join', '{}:2377'.format(manager), '--token', token.stdout.decode('utf-8').replace('\n', '')]) # join to cluster

    ####    ADD TAGS
    hostname = run(['hostname'], stdout=PIPE)
    if role == 'manager': # add init flag and hostname
        add_tag([{'Key': 'Init', 'Value': 'true'}, {'Key': 'Hostname', 'Value': hostname.stdout.decode('utf-8').replace('\n', '')}])
    else: # adds hostname only
        add_tag([{'Key': 'Hostname', 'Value': hostname.stdout.decode('utf-8').replace('\n', '')}])

    ####    CLEAN NODES
    if replaced_instances_count > 0 and role == 'manager':
        ## docker demote node && docker rm node
        for instance in replaced_instances:
            for tag in instance['Tags']:
                if tag['Key'] == 'Hostname':
                    call(["docker", "node", "demote", tag['Value']])
                    call(["docker", "node", "rm", tag['Value']])

    if replaced_workers_count > 0 and role == 'manager':
        ## docker rm node
        for instance in replaced_workers:
            for tag in instance['Tags']:
                if tag['Key'] == 'Hostname':
                    call(["docker", "node", "rm", tag['Value']])


else:
    ####    INIT CLUSTER
    call(["echo", "'Here I init the cluster'"])
    call(["docker", "swarm", "init"])

    ####    ADD TAGS
    hostname = run(['hostname'], stdout=PIPE)
    add_tag([{'Key': 'Init', 'Value': 'true'}, {'Key': 'Hostname', 'Value': hostname.stdout.decode('utf-8').replace('\n', '')}])
