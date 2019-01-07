require_relative 'spec_helper'

describe 'Application Container' do
  describe file('/etc/alpine-release') do
    its(:content) { is_expected.to match(/3.8.2/) }
  end

  describe 'java' do
    describe command('java -version') do
      its(:stderr) { is_expected.to match(/1.8.0_181/) }
    end

    describe process('java') do
      it { is_expected.to be_running }
      its(:args) { is_expected.to contain('gs-rest-service.jar') }
      its(:user) { is_expected.to eq('runner') }
    end

    describe 'listens to correct port' do
      it { wait_for(port(8080)).to be_listening.with('tcp') }
    end
  end

  describe file('gs-rest-service.jar') do
    it { is_expected.to be_file }
  end
end
