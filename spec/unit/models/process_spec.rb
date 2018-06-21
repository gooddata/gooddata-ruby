# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

# puts "Using DEFAULT_SERVER: #{GoodData::Environment::ConnectionHelper::DEFAULT_SERVER}"
# puts "Using PROJECT_ID: #{GoodData::Environment::ProjectHelper::PROJECT_ID}"
# puts "Using PROCESS_ID: #{GoodData::Environment::ProcessHelper::PROCESS_ID}"


describe GoodData::Process do
    before(:all) do
        # user = GoodData::Environment::ConnectionHelper::DEFAULT_USERNAME
        # password = GoodData::Environment::ConnectionHelper::DEFAULT_PASSWORD}"
        # project_id = GoodData::Environment::ProjectHelper::PROJECT_ID
        project_id = 'guec1btw971y0q3c7vxqacvno06lkstq'
        client = GoodData.connect()
        project = GoodData::Project[project_id, client: client]
        @archive_location = '/Users/vladimir.pachnik/Downloads/VPC - Playground'
        @options = {project: project, client: client}
        GoodData.project=(project)
    end

    after(:all) do
        GoodData.disconnect()
    end
    
    def create_process
        puts "Using project: #{GoodData.project.pid} to create process"
        GoodData::Process.deploy(@archive_location, @options.merge(name: 'Test process GRAPH'))
    end

    def destroy_process(process)
        process.delete
    end

    describe '#deploy' do        
        context 'as class method, deploying a GRAPH' do
            it 'should return a new process' do
                new_process = create_process
                expect(new_process).to be_an_instance_of(GoodData::Process)
                destroy_process(new_process)
            end
        end
    end

    describe '.deploy' do
        context 'as instance method, deploying a GRAPH' do
            it 'should redeploy the process and the object_id of returned object should stay the same' do
                new_process = create_process
                redeployed_process = new_process.deploy(@archive_location)
                expect(redeployed_process).to be_instance_of(GoodData::Process)
                expect(redeployed_process.process_id).to eql(new_process.process_id)
                destroy_process(redeployed_process)
            end    
        end
    end
end