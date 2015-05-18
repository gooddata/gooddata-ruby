# encoding: UTF-8

require 'pry'
require 'gooddata/models/model'

describe GoodData::Model do

  before(:each) do
    @blueprint_1 = double("blueprint_1")
    allow(@blueprint_1).to receive(:to_hash).and_return({
      title: "My blueprint",
      datasets: [
        name: "repos",
        columns: [
          {
            name: "repo_id",
            type: "anchor",
          },
          {
            name: "email",
            type: "label",
            reference: "repo_id"
          },
        ]
      ]
    })

    @blueprint_2 = double("blueprint_2")
    allow(@blueprint_2).to receive(:to_hash).and_return({
      title: "Cool title",
      datasets: [
        name: "repos",
        columns: [
          {
            name: "lines_changed",
            type: "fact",
          },
        ]
      ]
    })
    
    @dataset_1 = @blueprint_1.to_hash[:datasets].first
    @dataset_2 = @blueprint_2.to_hash[:datasets].first
  end


  describe "::DEFAULT_FACT_DATATYPE" do

    it "returns default fact datatype" do
      expect(GoodData::Model::DEFAULT_FACT_DATATYPE).to eq "DECIMAL(12,2)"
    end
  end


  describe ".title" do

    context "blueprint" do
      it "returns title" do
        expect(GoodData::Model.title(@blueprint_1.to_hash)).to eq "My blueprint"
      end
    end

    context "dataset" do
      it "returns name" do
        expect(GoodData::Model.title(@dataset_1)).to eq "Repos"
      end
    end

    context "unknown" do
      it "raises error" do
        expect { GoodData::Model.title({ something: "strange" }) }.to raise_error
      end
    end
  end


  describe ".identifier_for" do

    context "column omitted" do
      it "returns identifier for dataset" do
        expect(GoodData::Model.identifier_for(@dataset_1)).to eq "dataset.repos"
      end
    end

    context "column provided" do
      context "string" do
        it "returns identifier for column" do
          expect(GoodData::Model.identifier_for(@dataset_1, "repo_id")).to eq "attr.repos.repo_id"
        end
      end
      
      context "hash" do
        it "returns identifier for column" do
          expect(GoodData::Model.identifier_for(@dataset_1, { name: "something", type: "anchor_no_label" })
            ).to eq "attr.repos.factsof"

          expect(GoodData::Model.identifier_for(@dataset_1, { name: "something", type: "attribute" })
            ).to eq "attr.repos.something"

          expect(GoodData::Model.identifier_for(@dataset_1, { name: "something", type: "anchor" })
            ).to eq "attr.repos.something"

          expect(GoodData::Model.identifier_for(@dataset_1, { name: "something", type: "date_fact" })
            ).to eq "dt.repos.something"

          expect(GoodData::Model.identifier_for(@dataset_1, { name: "something", type: "fact" })
            ).to eq "fact.repos.something"

          expect(GoodData::Model.identifier_for(@dataset_1, { name: "something", type: "primary_label" })
            ).to eq "label.repos.something"

          expect(GoodData::Model.identifier_for(@dataset_1, { name: "something", type: "label", reference: "repo_id" })
            ).to eq "label.repos.repo_id.something"

          expect(GoodData::Model.identifier_for(@dataset_1, { name: "something", type: "date_ref" })
            ).to eq "repos.date.mdyy"
          
          expect(GoodData::Model.identifier_for(@dataset_1, { name: "something", type: "dataset" })
            ).to eq "dataset.repos"
          
          expect(GoodData::Model.identifier_for(@dataset_1, { name: "something", type: "date" })
            ).to eq "DATE"
          
          expect(GoodData::Model.identifier_for(@dataset_1, { name: "something", type: "reference" })
            ).to eq "REF"
        end
      end
      
      context "unexisting column name" do
        it "raises error" do
          expect { GoodData::Model.identifier_for(@dataset_1, "officer_id") }.to raise_error("Column officer_id not found")
        end
      end
      
      context "unknown column type" do
        it "raises error" do
          @dataset_1[:columns][0] = { name: "repo_id", type: "nonsense_type"}
          expect { GoodData::Model.identifier_for(@dataset_1, "repo_id") }.to raise_error("Unknown type nonsense_type")
        end
      end 
    end
  end


  describe ".has_gd_type?" do

    context "supported" do
      it "returns true" do
        expect(GoodData::Model.has_gd_type?("GDC.link")).to eq true
        expect(GoodData::Model.has_gd_type?("GDC.text")).to eq true
        expect(GoodData::Model.has_gd_type?("GDC.geo")).to eq true
        expect(GoodData::Model.has_gd_type?("GDC.time")).to eq true
      end
    end

    context "not supported" do
      it "returns false" do
        expect(GoodData::Model.has_gd_type?("gdc.time")).to eq false
        expect(GoodData::Model.has_gd_type?("GDC.time3")).to eq false
      end
    end
  end


  describe ".has_gd_datatype?" do

    context "supported" do
      it "returns true" do
        expect(GoodData::Model.has_gd_datatype?("INT")).to eq true
        expect(GoodData::Model.has_gd_datatype?("int")).to eq true
        
        expect(GoodData::Model.has_gd_datatype?("BIGINT")).to eq true
        expect(GoodData::Model.has_gd_datatype?("DOUBLE")).to eq true
        expect(GoodData::Model.has_gd_datatype?("INTEGER")).to eq true
        
        expect(GoodData::Model.has_gd_datatype?("VARCHAR(1)")).to eq true
        expect(GoodData::Model.has_gd_datatype?("DECIMAL(1,0)")).to eq true
        
        expect(GoodData::Model.has_gd_datatype?("VARCHAR(10)")).to eq true
        expect(GoodData::Model.has_gd_datatype?("DECIMAL(10,0)")).to eq true
        
        expect(GoodData::Model.has_gd_datatype?("VARCHAR(100)")).to eq true
        expect(GoodData::Model.has_gd_datatype?("DECIMAL(100,0)")).to eq true
      end
    end

    context "not supported" do
      it "returns false" do
        expect(GoodData::Model.has_gd_datatype?("VARCHAR(1234)")).to eq false
        expect(GoodData::Model.has_gd_datatype?("DECIMAL(1234,1234)")).to eq false
        
        expect(GoodData::Model.has_gd_datatype?("VARCHAR")).to eq false
        expect(GoodData::Model.has_gd_datatype?("DECIMAL")).to eq false
        
        expect(GoodData::Model.has_gd_datatype?("FLOAT")).to eq false
        expect(GoodData::Model.has_gd_datatype?("CHAR")).to eq false
      end
    end
    
    context "unknown predicate" do
      it "raises error" do
        expect { GoodData::Model.has_gd_datatype?(1_000) }.to raise_error
      end
    end
  end


  describe ".merge_dataset_columns" do

    context "unique column names" do
      it "returns dataset with all the columns" do
        result = GoodData::Model.merge_dataset_columns(@dataset_1, @dataset_2)

        expect(result[:columns].count).to be 3
        expect(result[:columns]).to include({name: "repo_id", type: "anchor" })
        expect(result[:columns]).to include({name: "email", type: "label", reference: "repo_id" })
        expect(result[:columns]).to include({name: "lines_changed", type: "fact" })
      end
    end

    context "shared column names" do
      context "shared column types" do
        it "returns dataset with unique columns only" do
          @dataset_1[:columns][1] = { name: "lines_changed", type: "fact" }

          result = GoodData::Model.merge_dataset_columns(@dataset_1, @dataset_2)

          expect(result[:columns].count).to be 2
          expect(result[:columns]).to include({name: "repo_id", type: "anchor" })
          expect(result[:columns]).to include({name: "lines_changed", type: "fact" })
        end
      end

      context "conflicting column types" do
        it "raises error" do
          @dataset_1[:columns][1] = { name: "lines_changed", type: "anchor" }

          expect { GoodData::Model.merge_dataset_columns(@dataset_1, @dataset_2) }.to raise_error
        end
      end
    end
  end
end