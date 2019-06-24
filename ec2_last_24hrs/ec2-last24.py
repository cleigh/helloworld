import boto3
import json
from datetime import date

date_filter = date.isoformat(date.today()) + '*'
#date_filter = "2019-06-21" + '*'
ec2 = boto3.resource('ec2')
ct_conn = boto3.client(service_name='cloudtrail',region_name='us-gov-west-1')

instances = ec2.instances.filter(Filters=[{'Name':'launch-time', 'Values':[date_filter]}])
for instance in instances:   
   events_dict= ct_conn.lookup_events(LookupAttributes=[{'AttributeKey':'ResourceName', 'AttributeValue':instance.instance_id}])
   for data in events_dict['Events']:
      json_file = json.loads(data['CloudTrailEvent'])
      print(instance.instance_id, instance.launch_time, instance.private_ip_address, json_file['userIdentity']['sessionContext']['sessionIssuer']['userName'])
      # print(instance.instance_id, instance.launch_time, instance.private_ip_address)





