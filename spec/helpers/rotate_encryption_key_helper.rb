# encoding: UTF-8
#
# Copyright (c) 2010-2021 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Helpers
    module RotateKeysHelper
      class << self
        def rotate_encryption_key(current_key, new_key)
          # Update credentials in secrets.yaml file
          yaml_file = 'spec/environment/secrets.yaml'
          secrets = YAML.load_file(yaml_file)
          secrets.each do | key, _|
            env_secrets = secrets[key]
            env_secrets.each do | item_key, item_value|
              env_secrets[item_key] = GoodData::Helpers.encrypt(GoodData::Helpers.decrypt(item_value, current_key), new_key)
            end
          end
          File.write(yaml_file, secrets.to_yaml)
          # Update BigQuery encryption key in bigquery_encrypted file
          bigquery_encrypted_file = 'spec/environment/bigquery_encrypted'
          File.write(bigquery_encrypted_file, GoodData::Helpers.encrypt(GoodData::Helpers.decrypt(File.read(bigquery_encrypted_file), current_key), new_key))
          # Update PGP encryption key in rubydev_secret_keys.gpg.encrypted file
          secret_keys_file = 'rubydev_secret_keys.gpg.encrypted'
          File.write(secret_keys_file, GoodData::Helpers.encrypt(GoodData::Helpers.decrypt(File.read(secret_keys_file), current_key), new_key))
          # Update PGP encryption key in rubydev_public.gpg.encrypted file
          public_key_file = 'rubydev_public.gpg.encrypted'
          File.write(public_key_file, GoodData::Helpers.encrypt(GoodData::Helpers.decrypt(File.read(public_key_file), current_key), new_key))
          # Update PGP encryption key in rubydev_public.gpg.encrypted file
          sso_key_file = 'dev-gooddata-sso.pub.encrypted'
          File.write(sso_key_file, GoodData::Helpers.encrypt(GoodData::Helpers.decrypt(File.read(sso_key_file), current_key), new_key))
        end
      end
    end
  end
end
