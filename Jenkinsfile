/*
 * Copyright (C) 2007-2018, GoodData(R) Corporation. All rights reserved.
 */

@Library('pipelines-shared-libs')
import com.gooddata.pipeline.Pipeline

def config = [
        'microservices': [
                'lcm-bricks': [
                        'docker': [
                                'dockerfile': './Dockerfile',
                                'arguments': [
                                        'BRICKS_VERSION': { readFile('./VERSION').trim() }
                                ]
                        ]
                ]
        ]
]

Pipeline.get(this, config).run()
