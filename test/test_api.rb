# frozen_string_literal: true

require "test_helper"

module VespaRuby
  class TestApi < ActiveSupport::TestCase
    def setup
      @api = VespaRuby::Api.new
    end

    def teardown
      # Keep config/ENV from leaking between tests.
      VespaRuby.reset_config!
      ENV["VESPA_URL"] = nil
    end

    # Throwaway self-signed cert/key (PEM) for exercising the mTLS plumbing.
    def throwaway_cert_and_key
      key = OpenSSL::PKey::RSA.new(2048)
      cert = OpenSSL::X509::Certificate.new
      cert.version = 2
      cert.serial = 1
      cert.subject = cert.issuer = OpenSSL::X509::Name.parse("/CN=test")
      cert.public_key = key.public_key
      cert.not_before = Time.now - 60
      cert.not_after = Time.now + 3600
      cert.sign(key, OpenSSL::Digest.new("SHA256"))
      [cert.to_pem, key.to_pem]
    end

    test "initialize" do
      assert_kind_of VespaRuby::Api, @api
      assert @api.conn.is_a?(Faraday::Connection)
      # assert_equal @api.url, "http://localhost:8080"
    end

    test "initialize sets default timeouts" do
      assert_equal VespaRuby::Api::DEFAULT_TIMEOUT, @api.conn.options.timeout
      assert_equal VespaRuby::Api::DEFAULT_OPEN_TIMEOUT, @api.conn.options.open_timeout
    end

    test "initialize with custom timeouts" do
      api = VespaRuby::Api.new(timeout: 30, open_timeout: 2)
      assert_equal 30, api.conn.options.timeout
      assert_equal 2, api.conn.options.open_timeout
    end

    test "initialize with VESPA_URL" do
      url = "https://vespa-host:8080"
      ENV["VESPA_URL"] = url

      api = VespaRuby::Api.new
      assert_equal url, api.url

      ENV["VESPA_URL"] = nil
    end

    test "initialize without client cert leaves ssl unconfigured (plain HTTP)" do
      api = VespaRuby::Api.new
      assert_nil api.conn.ssl.client_cert
      assert_nil api.conn.ssl.client_key
    end

    test "VespaRuby.configure sets url, client_cert and client_key" do
      cert_pem, key_pem = throwaway_cert_and_key
      VespaRuby.configure do |c|
        c.url = "https://configured-host:8080"
        c.client_cert = cert_pem
        c.client_key = key_pem
      end

      api = VespaRuby::Api.new
      assert_equal "https://configured-host:8080", api.url
      assert_kind_of OpenSSL::X509::Certificate, api.conn.ssl.client_cert
      assert_kind_of OpenSSL::PKey::PKey, api.conn.ssl.client_key
    end

    test "explicit cert/key args override config and enable mTLS" do
      cert_pem, key_pem = throwaway_cert_and_key
      api = VespaRuby::Api.new(client_cert: cert_pem, client_key: key_pem)
      assert_kind_of OpenSSL::X509::Certificate, api.conn.ssl.client_cert
      assert_kind_of OpenSSL::PKey::PKey, api.conn.ssl.client_key
    end

    test "host_url arg overrides configured url" do
      VespaRuby.configure { |c| c.url = "https://configured-host:8080" }
      api = VespaRuby::Api.new("https://explicit-host:8080")
      assert_equal "https://explicit-host:8080", api.url
    end

    # Uses VCR test/cassettes/test_api
    test "up?" do
      assert @api.up?
    end

    test "raw search by POST" do
      yql = "select * from sources * where name contains 'Congress'"
      hits = 10

      post_body = {yql: yql, hits: hits}.to_json

      result = @api.raw_search_post(post_body)

      assert result
      assert_equal 200, result.status
      assert_equal 10, result.children.length
      assert_equal 618, result.total_count
    end

    test "raw_search_post raises Faraday::Error on transport failure" do
      @api.conn.define_singleton_method(:post) { |*| raise Faraday::ConnectionFailed, "boom" }

      assert_raises(Faraday::Error) do
        @api.raw_search_post("{}")
      end
    end

    test "execute_search yql" do
      yql_query = YqlQuery.select("*").from("sources *").where("name contains 'congress'")
      vespa_request = yql_query.build_request(options: {limit: 10})

      response = @api.execute_search(vespa_request)

      assert response.is_a?(VespaResponse)
      assert_equal 200, response.status
      assert_equal 10, response.children.count
      assert_equal 618, response.total_count
      assert response.field_list.include?("documentid")
    end

    test "execute_search simple query" do
      simple_query = SimpleQuery.query("apples")
      vespa_request = simple_query.build_request(options: {hits: 5})

      response = @api.execute_search(vespa_request)

      assert response.is_a?(VespaResponse)
      assert_equal 200, response.status
      assert_equal 5, response.children.count
      assert_equal 328, response.total_count
      assert response.field_list.include?("documentid")
    end

    test "execute_search simple query with yql" do
      simple_query = SimpleQuery.query("president commission").filter("-'pro tempore'")
        .select("id", "name", "lawKey", "path")
        .from("laws_content")
        .where(WhereOp.contains("jurisdiction", "FED"))
      vespa_request = simple_query.build_request(options: {hits: 10})

      response = @api.execute_search(vespa_request)

      assert response.is_a?(VespaResponse)
      assert_equal 200, response.status
      assert_equal 10, response.children.count
      assert_equal 3084, response.total_count
      assert response.field_list.include?("id")
      assert response.field_list.include?("name")
    end

    test "execute_search errors gets populated" do
      simple_query = SimpleQuery.query("")
      vespa_request = simple_query.build_request(options: {hits: 5})

      response = @api.execute_search(vespa_request)

      assert response.is_a?(VespaResponse)
      assert_equal 400, response.status
      assert_equal "Bad Request", response.reason_phrase
      assert_equal "No query", response.errors.first["message"]
    end
  end
end
