#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Copyright: (c) 2025, GoodData

import requests
import time
import sys
import os
import json
import re
import argparse

from urllib.parse import urljoin


# Rundeck execution statuses
# Terminal statuses (execution is finished)
TERMINAL_STATUSES = ['succeeded', 'failed', 'aborted', 'timedout', 'failed-with-retry', 'other']
# Non-terminal statuses: 'running', 'scheduled' (execution is still active)

class RundeckJobTrigger(object):
    def __init__(self, rundeck_server, project, job_group, job_name, job_parameters, client_cert_pem):
        self.rundeck_server = rundeck_server
        self.project = project
        self.job_group = job_group
        self.job_name = job_name
        self.job_parameters = job_parameters
        self.ss = requests.Session()
        self.ss.cert = client_cert_pem
        # Set headers for JSON requests
        self.ss.headers.update({
            'Content-Type': 'application/json',
            'Accept': 'application/json'
        })

    def find_job_id(self):
        """Find job ID based on project, group, and name"""
        jobs_url = urljoin(self.rundeck_server, f'api/39/project/{self.project}/jobs')

        print(f"Looking for job '{self.job_name}' in group '{self.job_group}' in project '{self.project}'")

        jobs_req = self.ss.get(jobs_url)
        jobs_req.raise_for_status()

        jobs_data = jobs_req.json()

        for job in jobs_data:
            job_group = job.get('group', '')  # Group can be empty string
            job_name = job.get('name', '')

            if job_group == self.job_group and job_name == self.job_name:
                job_id = job.get('id')
                print(f"Found job ID: {job_id}")
                return job_id

        raise Exception(f'Job not found: group="{self.job_group}", name="{self.job_name}" in project "{self.project}"')

    def rundeck_run_job(self):
        # First find the job ID
        job_id = self.find_job_id()

        # Rundeck API endpoint for running a job
        run_job_url = urljoin(self.rundeck_server, f'api/39/job/{job_id}/run')

        # Prepare job execution request
        job_request = {}

        if self.job_parameters:
            # Convert parameters to Rundeck options format
            job_request['options'] = self.job_parameters

        print(f"Running job {job_id} ({self.job_group}/{self.job_name}) in project {self.project}")
        print(f"Parameters: {self.job_parameters}")

        job_run_req = self.ss.post(run_job_url, json=job_request)
        job_run_req.raise_for_status()

        execution_data = job_run_req.json()
        execution_id = execution_data.get('id')
        execution_url = execution_data.get('permalink')

        if not execution_id:
            raise Exception('No execution ID returned from Rundeck')

        print(f"Execution started with ID: {execution_id}")
        if execution_url:
            print(f"View execution: {execution_url}")

        return self.check_execution_status(execution_id)

    def check_execution_status(self, execution_id):
        execution_info_url = urljoin(self.rundeck_server, f'api/39/execution/{execution_id}')

        print("Waiting for execution to complete...")
        while True:
            execution_req = self.ss.get(execution_info_url)
            execution_req.raise_for_status()

            execution_data = execution_req.json()
            status = execution_data.get('status')

            if status in TERMINAL_STATUSES:
                break

            print(f"Execution status: {status}, waiting...")
            time.sleep(5)


        execution_result = {
            'job_execution_status': execution_data.get('status'),
            'job_execution_url': execution_data.get('permalink'),
            'execution_id': execution_data.get('id')
        }

        return execution_result


def parse_params(params_str):
    """Parse parameters string as JSON"""
    if not params_str:
        return {}

    try:
        return json.loads(params_str)
    except json.JSONDecodeError as e:
        raise ValueError(f"Invalid JSON parameters: {params_str}. Error: {e}")


def main():
    parser = argparse.ArgumentParser(
        description='Trigger Rundeck job execution',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument('--cert-path', required=True, help='Path to client certificate in PEM format')
    parser.add_argument('--server', required=True, help='Rundeck server hostname (without https://)')
    parser.add_argument('--project', required=True, help='Project name containing the job')
    parser.add_argument('--job-group', required=True, help='Job group name')
    parser.add_argument('--job-name', required=True, help='Job name')
    parser.add_argument('--params', default='{}', help='Job parameters as JSON string (e.g., \'{"key": "value"}\')')

    args = parser.parse_args()

    params = parse_params(args.params)

    trigger = RundeckJobTrigger(
        rundeck_server=f"https://{args.server}",
        project=args.project,
        job_group=args.job_group,
        job_name=args.job_name,
        job_parameters=params,
        client_cert_pem=args.cert_path
    )

    trigger_result = trigger.rundeck_run_job()

    # Write outputs for GitHub Actions
    with open(os.environ["GITHUB_OUTPUT"], "a") as f:
        print(f'execution_status={trigger_result["job_execution_status"]}', file=f)
        print(f'url={trigger_result["job_execution_url"]}', file=f)

    # Check job status and exit with appropriate code
    job_status = trigger_result["job_execution_status"]
    if job_status == 'succeeded':
        print("Job completed successfully")
        sys.exit(0)
    else:
        print(f"Job failed with status: {job_status}")
        sys.exit(1)


if __name__ == '__main__':
    main()
