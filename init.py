import boto3
import os
from subprocess import run
from subprocess import call
from subprocess import PIPE

ec2 = boto3.client('ec2')
role = os.environ['ROLE']
instance = os.environ['INSTANCE']

def add_tag():
    response_tags = ec2.create_tags(
        Resources=[
            instance
        ],
        Tags=[
            {
                'Key': 'Init',
                'Value': 'true'
            }
        ]
    )
    print(response_tags)

response = ec2.describe_instances(
    Filters=[
        {
            'Name': 'tag:Name',
            'Values': ['SwarmManager']
        },
        {
            'Name': 'instance-state-name',
            'Values': ['running']
        },
        {
            'Name': 'tag:Init',
            'Values': ['true']
        }
    ]
)

instances = 0
for res in response['Reservations']:
    instances += len(res['Instances'])

print(instances)
if instances > 0 or role == 'worker':
    manager = response['Reservations'][0]['Instances'][0]['PrivateIpAddress']
    call(["echo","'Here I join to the cluster {}'".format(manager)])
    token = run(["docker","-H {}:2376".format(manager),"swarm","join-token","-q","{}".format(role)],stdout=PIPE)
    call(['docker','swarm','join','{}:2377'.format(manager),'--token','{}'.format(token.stdout.decode('utf-8').replace('\n',''))])
    if role == 'manager':
        add_tag()
else:
    call(["echo","'Here I init the cluster'"])
    call(["docker","swarm","init"])
    add_tag()
