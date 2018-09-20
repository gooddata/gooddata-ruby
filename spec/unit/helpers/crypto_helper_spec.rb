# encoding: UTF-8
#
# Copyright (c) 2010-2018 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/helpers/crypto_helper'

describe GoodData::Helpers::CryptoHelper do
  describe '.generate_password' do
    subject { GoodData::Helpers::CryptoHelper.generate_password }
    let(:lower_case) { /[a-z]+/ }
    let(:upper_case) { /[A-Z]+/ }
    let(:digit) { /\d+/ }
    let(:special_character) { /[^a-zA-Z\d\s]/ }

    it { is_expected.not_to be_empty }
    it { is_expected.to match(lower_case) }
    it { is_expected.to match(upper_case) }
    it { is_expected.to match(digit) }
    it { is_expected.to match(special_character) }

    it 'has at least 32 characters' do
      expect(subject.length).to be >= 32
    end
  end
end
