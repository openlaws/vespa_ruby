# frozen_string_literal: true

require "test_helper"

module VespaRuby
  class TestYqlQuery < ActiveSupport::TestCase
    include ::VespaRuby::WhereOp

    test "initializes with select(...)" do
      q_single_field = YqlQuery.select("field")

      assert q_single_field.is_a?(VespaRuby::YqlQuery)
      assert "select field", q_single_field.select_value

      q_field_array = YqlQuery.select(%w[field1 field2])

      assert q_field_array.is_a?(VespaRuby::YqlQuery)
      assert "select field1, field2", q_single_field.select_value
    end

    test "build_annotations" do
      query = YqlQuery.new

      single_annotation = query.build_annotations({distance: 5})
      assert_equal "{distance: 5}", single_annotation

      single_boolean = query.build_annotations({startAnchor: true})
      assert_equal "{startAnchor: true}", single_boolean

      annotation_only = query.build_annotations({distance: 5, defaultIndex: "default"})
      assert_equal "{distance: 5, defaultIndex: \"default\"}", annotation_only

      annotation_with_phrase = query.build_annotations({distance: 5, defaultIndex: "default"}, "near(\"a\", \"b\"")
      assert_equal "({distance: 5, defaultIndex: \"default\"}near(\"a\", \"b\")", annotation_with_phrase
    end

    test "select clause with single field" do
      q_default = YqlQuery.select
      assert_equal "select *", q_default.select_value

      q = YqlQuery.select("field")
      assert_equal "select field", q.select_value

      q2 = YqlQuery.select(["field1", "field2"])
      assert_equal "select field1, field2", q2.select_value
    end

    test "from clause" do
      q_default = YqlQuery.new.from
      assert_equal "from sources *", q_default.from_value

      q_one_source = YqlQuery.new.from("source_a")
      assert_equal "from source_a", q_one_source.from_value
    end

    test "where clause" do
      q = YqlQuery.new.where("true")
      assert_equal "where true", q.where_value
    end

    test "model.restrict" do
      q = YqlQuery.select.from.where("true").restrict("my_schema")
      assert_equal "my_schema", q.model_restrict
      # rubocop:disable Style/HashSyntax
      expected = {:"model.restrict" => "my_schema"}
      # rubocop:enable Style/HashSyntax
      assert_equal expected, q.build_request.query_model
    end

    test "model.sources" do
      q = YqlQuery.select.from.where("true").sources("my_cluster")
      assert_equal "my_cluster", q.model_sources

      # rubocop:disable Style/HashSyntax
      expected = {:"model.sources" => "my_cluster"}
      # rubocop:enable Style/HashSyntax
      assert_equal expected, q.build_request.query_model
    end

    test "ranking.profile" do
      q = YqlQuery.select.from.where("true").ranking_profile("bm25_anc_heavy")
      assert_equal "bm25_anc_heavy", q.ranking_profile_value

      # rubocop:disable Style/HashSyntax
      expected = {:"ranking.profile" => "bm25_anc_heavy"}
      # rubocop:enable Style/HashSyntax
      assert_equal expected, q.build_request.ranking
    end

    test "ranking.profile unset leaves ranking empty" do
      q = YqlQuery.select.from.where("true")
      assert_equal({}, q.build_request.ranking)
    end

    test "ranking_profile setter wins over raw options[:ranking] and preserves other ranking keys" do
      q = YqlQuery.select.from.where("true").ranking_profile("winner")
      req = q.build_request(options: {ranking: {"ranking.profile": "stale", "ranking.listFeatures": true}})

      # rubocop:disable Style/HashSyntax
      expected = {:"ranking.profile" => "winner", :"ranking.listFeatures" => true}
      # rubocop:enable Style/HashSyntax
      assert_equal expected, req.ranking
    end

    test "chaining basic queries" do
      q1 = YqlQuery.select.from("doc").where("true")
      assert_equal "select * from doc where true", q1.build_yql_string

      q2 = YqlQuery.select.from("doc").where(WhereOp.contains("title", "ranking"))
      assert_equal "select * from doc where title contains \"ranking\"", q2.build_yql_string

      q3 = YqlQuery.select.from("doc").where(WhereOp.contains("title", "ranking"))
      assert_equal "select * from doc where title contains \"ranking\"", q3.build_yql_string
    end

    test "build_yql_hash" do
      skip "TODO"
    end

    test "build_request" do
      skip "TODO"
    end
  end
end
