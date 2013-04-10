require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'wortsammler', 'class.Traceable.rb'))

require 'tmpdir'

describe TraceableSet do

  before :all do
    @set=TraceableSet.new
    @second_set=TraceableSet.new
  end

  it "should return a blank instance" do
    TraceableSet.new.class.should == TraceableSet
  end

  it "allows to add Traceables" do
    x=Traceable.new
    x.id="foo0"
    x.origin="0"
    @set.add(x)

    @set["foo"].nil?.should == true
    @set["foo0"].id.should == "foo0"
  end

  it "delivers the first of the duplicates" do
    x=Traceable.new
    x.id="xfoo"
    x.origin="1"
    @set.add(x)

    x=Traceable.new
    x.id="xfoo"
    x.origin="2"
    @set.add(x)
    y=@set["xfoo"]


    y.id.should     == "xfoo"
    y.class.should  == Traceable
    y.origin.should == "1"

    x.origin="2.2"
    @set["xfoo"].origin.should == "1"
  end

  it "advertises duplicates" do
    x=Traceable.new
    x.id="foo"
    x.origin="1"
    @set.add(x)

    x=Traceable.new
    x.id="bar"
    x.origin="2"
    @set.add(x)

    x=Traceable.new
    x.id="foo"
    x.origin="3"
    @set.add(x)

    x=Traceable.new
    x.id="bar"
    x.origin="4"
    @set.add(x)

    x=Traceable.new
    x.id="foobar"
    x.origin="5"
    @set.add(x)

    @set.duplicate_ids.count.should == 3
    @set.duplicate_ids[0].should == "bar"
    @set.duplicate_ids[1].should == "foo"

    @set.duplicate_traces[0][0].origin.should == "2"
    @set.duplicate_traces[0][1].origin.should == "4"
    @set.duplicate_traces[1][0].origin.should == "1"
    @set.duplicate_traces[1][1].origin.should == "3"

  end

  it "adertises undefined traceables" do
    x=Traceable.new
    x.id="rs_xy_001"
    x.origin="1"
    x.contributes_to = ["rs_xy_002", "rs_xy_003", "rs_xy_004", "rs_xy_005"]
    @set.add(x)

    x=Traceable.new
    x.id="rs_xy_002"
    x.origin="2"
    x.contributes_to = ["rs_xy_001", "rs_xy_003", "rs_xy_004", "rs_xy_005"]
    @set.add(x)


    undefineds       = @set.undefined_ids
    undefineds.count.should == 3
  end

  it "advertises all traceables" do
    @set.all_trace_ids.should == ["bar", "foo", "foo0", "foobar", "rs_xy_001", "rs_xy_002", "xfoo"]
  end

  it "advertises a hash of supporting traces" do
    @set.uptrace_ids["rs_xy_001"].should == ["rs_xy_002"]
  end

  it "advertises traceable ids of a particular category" do
    x=Traceable.new
    x.id="rs_spec_000"
    x.origin="1"
    x.category=:spec_item
    @set.add(x)

    x=Traceable.new
    x.id="rs_spec_001"
    x.origin="2"
    x.category=:spec_item
    @set.add(x)

    @set.all_trace_ids(:spec_item).should == ["rs_spec_000", "rs_spec_001"]
  end

  it "advertises ttraceables of a particular category" do
    @set.all_traces(:spec_item).first.id.should == "rs_spec_000"
  end

  it "merges traceables" do
    x=Traceable.new
    x.id="rs_merge_001"
    x.origin="2"
    @second_set.add(x)

    x=Traceable.new
    x.id="rs_merge_002"
    x.origin="2"
    x.category=:spec_item
    @second_set.add(x)

    x=Traceable.new
    x.id="rs_merge_002"
    x.origin="2"
    x.category=:spec_item
    @set.add(x)

    @second_set.merge(@set)
    wanted = ["bar", "foo", "foo0", "foobar", "rs_merge_001", "rs_merge_002", "rs_spec_000", "rs_spec_001", "rs_xy_001", "rs_xy_002", "xfoo"]
    got = @second_set.all_trace_ids
    dups = @second_set.duplicate_ids
    @second_set.all_trace_ids.should == wanted
  end

  it "exposes deleted Traceables" do
    x=Traceable.new
    x.id="rs_deleted_001"
    x.origin="2"
    x.category=:spec_item
    @second_set.add(x)

    @set.deleted_trace_ids(@second_set).should == ["rs_deleted_001", "rs_merge_001"]
  end

  it "exposes added Traceables" do
    x=Traceable.new
    x.id="rs_added_001"
    x.origin="2"
    x.category=:spec_item
    @set.add(x)

    @set.added_trace_ids(@second_set).should == ["rs_added_001"]
  end

  it "exposes deleted Traceables of category" do
    @set.deleted_trace_ids(@second_set, :spec_item).should == ["rs_deleted_001"]
  end

  it "exposes added Traceables of category" do
    x=Traceable.new
    @set.added_trace_ids(@second_set, :spec_item).should == ["rs_added_001"]
  end

  it "exploses changed traceids as array of [Traceid, levensthein, diff_as_html]" do
    x=Traceable.new
    x.id="rs_changed_001"
    x.header_orig="this is headline"
    x.body_orig="Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet."
    x.origin="3"
    x.category=:spec_item
    @set.add(x)

    y=Traceable.new
    y.id="rs_changed_001"
    y.header_orig="this is the headline"
    y.body_orig="Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sede diam nonumy diadem tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet."
    y.origin="4"
    y.category=:spec_item
    y.origin="4"
    @second_set.add(y)

    puts @set.changed_trace_ids(@second_set).should == [["rs_changed_001", "n/a", "<div class=\"diff\">\n  <ul>\n    <li class=\"unchanged\"><span></span></li>\n  </ul>\n</div>\n"]]
  end

  it "exposes unchanged Traceables" do
    @set.unchanged_trace_ids(@second_set).should == ["bar", "foo", "foo0", "foobar", "rs_merge_002", "rs_spec_000", "rs_spec_001", "rs_xy_001", "rs_xy_002", "xfoo"]
  end

  it "can be marshalled to a file" do
    dumpfile = "#{Dir.mktmpdir}/traceable-set.dmp"

    @set.dump_to_marshal(dumpfile)
    @newset=TraceableSet.load_from_marshal(dumpfile)

    @set.inspect.gsub(/0x[0-9a-z]+/, "x").should==@newset.inspect.gsub(/0x[0-9a-z]+/, "x")
  end


  it "can be dumped to a graphml file" do
    GRAHPHML = "traceable-set.graphml"
    myset=TraceableSet.new

    t0=Traceable.new
    t0.id="t0"
    myset.add(t0)

    t1=Traceable.new
    t1.id="t1"
    t1.contributes_to= ["t0"]
    myset.add(t1)

    t2=Traceable.new
    t2.id="t2"
    t2.contributes_to= ["t0"]
    myset.add(t2)

    t10= Traceable.new
    t10.id = "t10"
    t10.contributes_to = ["t1", "t2"]
    myset.add(t10)

    t20= Traceable.new
    t20.id = "t20"
    t20.contributes_to = ["t2", "t1"]
    myset.add(t20)

    t100 = Traceable.new
    t100.id="t100"
    t100.contributes_to = ["t10"]
    myset.add(t100)

    t200 = Traceable.new
    t200.id="t200"
    t200.contributes_to = ["t20"]
    myset.add(t200)


    observed = myset.to_graphml()
    expected = File.new("#{File.dirname(__FILE__)}/test.graphml").readlines.join
    observed.should==expected
    nil
  end


end


describe Traceable do

  before :all do
    @x = Traceable.new
    @x.id             = "id"
    @x.origin         = "origin"
    @x.alternative_id = "alternative_id"
    @x.header_plain   = "header_plain"
    @x.header_orig    = "\\textt{header_origin}"
    @x.body_plain     = "body_plain"
    @x.contributes_to = ["contributes_to"]
    @x.trace_orig     = "trace_orig"
    @x.origin         = "origin"
    @x.category       = "category"
    @x.info           = "info"
  end


  specify { @x.id.should             == "id" }
  specify { @x.origin.should         == "origin" }
  specify { @x.alternative_id.should == "alternative_id" }
  specify { @x.header_plain.should   == "header_plain" }
  specify { @x.header_orig.should    == "\\textt{header_origin}" }
  specify { @x.body_plain.should     == "body_plain" }
  specify { @x.contributes_to.should == ["contributes_to"] }
  specify { @x.trace_orig.should     == "trace_orig" }
  specify { @x.origin.should         == "origin" }
  specify { @x.category.should       == "category" }
  specify { @x.info.should           == "info" }


end
