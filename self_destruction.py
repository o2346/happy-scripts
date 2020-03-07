import os
import boto3

lclient = boto3.client ('lambda')
print ('function loaded')

def lambda_handler(event, context):
    lclient.delete_function (FunctionName = context.function_name)
    print ('I am deleted')
    return True
