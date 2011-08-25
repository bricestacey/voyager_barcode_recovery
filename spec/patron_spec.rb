require 'spec_helper'

describe Barcode::Patron do
  it { should_not have_valid(:first_name).when(nil, '') }
  it { should_not have_valid(:last_name).when(nil, '') }
  it { should_not have_valid(:barcode).when(nil, '') }
  it { should_not have_valid(:patron_group).when(nil, '') }
  it { should_not have_valid(:email).when(nil, '') }
end
