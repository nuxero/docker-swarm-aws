var AWS = require('aws-sdk');
var ec2 = new AWS.EC2();
var exec = require('child_process').exec;
var role = process.env.ROLE;
var instance = process.env.INSTANCE

var params = {
    Filters: [{
            Name: 'tag:Name',
            Values: ['SwarmManager']
        },
        {
            Name: 'instance-state-name',
            Values: ['running']
        },
        {
            Name: 'tag:Init',
            Values: ['true']
        }
    ]
}

ec2.describeInstances(params, (err, data) => {
    if (err) console.log(err);
    else {
        var instances = 0;
        data.Reservations.forEach(res => {
            instances += res.Instances.length
        })
        console.log('Managers: ',instances);
        if (instances > 0 || role == 'worker') {
            exec(`echo 'Here I join to the cluster ${data.Reservations[0].Instances[0].PrivateIpAddress}'`, puts);
            exec(`docker swarm join ${data.Reservations[0].Instances[0].PrivateIpAddress}:2377 --token $(docker -H ${data.Reservations[0].Instances[0].PrivateIpAddress}:2376 swarm join-token -q ${role})`, puts);
            if (role == 'manager') addTag();
        } else {
            exec(`echo 'Here I create to the cluster'`, puts);
            exec(`docker swarm init`, puts);
            addTag();
        }
    }
});

function puts(error, stdout, stderr) {
    console.log(stdout, stderr)
}

function addTag() {
    var tag_params = {
        Resources: [
            instance
        ],
        Tags: [{
            Key: 'Init',
            Value: 'true'
        }]
    }
    ec2.createTags(tag_params, (err, data) => {
        if (err) console.log(err, err.stack); // an error occurred
        else console.log(data); // successful response
    });
}
