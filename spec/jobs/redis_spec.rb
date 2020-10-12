require 'bosh/template/test'

describe 'redis job' do
  let(:release) { Bosh::Template::Test::ReleaseDir.new(File.join(File.dirname(__FILE__), '../..')) }
  let(:job) { release.job('redis') }

  let(:link) {

  }

  describe "redis.conf.part" do
    let(:template) { job.template('config/redis.conf.part') }

    links = [      
      Bosh::Template::Test::Link.new(
        name: 'redis',
        instances: [Bosh::Template::Test::LinkInstance.new(address: '1.2.3.4', bootstrap: true)],
        properties: {
          'password' => 'asdf1234',
          'port' => 4321,
          'base_dir' => '/redis',
        }
      )
    ]

    it 'renders template with no errors' do
      expect {
        template.render({}, consumes: links)
      }.to_not raise_error
    end
  end
end