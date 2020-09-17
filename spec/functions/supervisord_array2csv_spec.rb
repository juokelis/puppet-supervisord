require 'spec_helper'

describe 'supervisord::array2csv' do
  it { is_expected.not_to eq nil }
  it { is_expected.to run.with_params(['value1']).and_return('value1') }
  it { is_expected.to run.with_params(['value1', 'value2', 'value3']).and_return('value1,value2,value3') }
  it { is_expected.to run.with_params('foo').and_raise_error(ArgumentError) }
  it { is_expected.to run.with_params().and_raise_error(ArgumentError) }
end
