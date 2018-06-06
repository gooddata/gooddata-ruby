# Provisioning Brick

This brick provides seamless client/project provisioning within domain or segment specified.

## Key Features:
From a high level perspective this brick can do for you

- Creation of clients
  - provision of the projects if necessary
  - deployment of the processes from master project
  - transfer of dashboards from release
- Removal of clients
  - removal of old clients including their respective projects

### Notes

The brick does not take care of transferring and updating your existing projects after a new release. It should be part of release to migrate existing projects to the latest version. It is also highly recommended not to update the master projects in place.

## Parameters

| Name                                              | Type   | Mandatory | Default    | Description                        |
|:--------------------------------------------------|:-------|:----------|:-----------|:-----------------------------------|
| <ul><li>`organization`</li><li>`domain`</li></ul> | String | Yes       | N/A        | Name of domain to be provisioned   |
| associate                                         | String | No        | false      | Run association part               |
| provision                                         | String | No        | false      | Run provisioning part              |
| client_id_column                                  | String | No        | client_id  | Name of column containing Client ID |
| segment_id_column                                 | String | No        | segment_id | Name of column containing Segment ID |
| project_id_column                                 | String | No        | project_id |  Name of column containing Project ID |
| delete_projects                                   | String | No        | false      | Delete existing projects not specified in input source |
| technical_client                                  | String | Yes       | N/A        | Name of Technical Client |
| s3_access_key_id                                  | String | No        | N/A        | S3 Input Source Access Key ID |
| s3_secret_access_key                              | String | No        | N/A        | S3 Input Source Secret Access Key |
| s3_bucket                                         | String | No        | N/A        | S3 Input Source Name of Bucket |
| s3_prefix                                         | String | No        | N/A        | S3 Input Source Prefix |

## Prerequisites

Before the brick is run there are couple of prerequisits

- You have to own a whitelabeled domain
- The segments need to be created and have master projects
- There has to be release done

## Input file

The brick expects to receive the data about which client should be provisioned under which segment. The general format looks like this


The brick accepts all typical input sources (currently project_staging, ADS, AWS S3). For further details how to set them up please have a look [here](/README.md#input-data-sources).

| segment_id      | client_id |
|-----------------|-----------|
| basic_segment   | client_1  |
| premium_segment | client_2  |

### Custom file headers

If your file is in the same format but the headers are differen you can specify alternative names of the columns.

| field      | default column name | parameter name for setting that column |
|------------|---------------------|----------------------------------------|
| segment id | segment_id          | segment_id_column                      |
| client id  | client_id           | client_id_column                       |
