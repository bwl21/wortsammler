#
# These class represents the management of Traceable object
#
# TraceableSet
# Traceable
#

require 'rubygems'
require 'nokogiri'
#require 'amatch'
require 'diffy'
#require 'ruby-debug'

# this class represents a set of traceables
class TraceableSet


  public

  #
  # Initialize the traceable set
  #
  # @return [type] [description]
  def initialize()
    # the traces
    @traces={}

    # the list of supporters
    # supporters for foo 0 @@supported_by["foo"]
    @supported_by={}


    # define the sort order policy
    # it is the same for all slots
    @sortOrder=[]

  end

  #
  # [add add a traceable to the Traceable set]
  # @param  traceable [Traceable] The traceable which shall be added
  #    * first
  #    * second
  #
  # @return [type] [description]
  def add(traceable)
    #TOOD: check traceable
    #TODO: check if append can be optimized

    @traces[traceable.id] = [@traces[traceable.id], traceable].flatten.compact

    traceable.contributes_to.each do |t|
      @supported_by[t] = [@supported_by[t], traceable.id].flatten.compact
    end
  end


  #
  # expose added traceables found as a result of comparing two TraceableSets
  # @param  reference_set [TraceableSet] The set of traceables used as reference
  # @param  category  [Symbol] Restrict the comparison to a particlar category
  #
  # @return [Array] the ids of the added traces (list of trace_id which are not in @referece_set)
  def added_trace_ids(reference_set, category=nil)
    self.all_trace_ids(category) - reference_set.all_trace_ids(category)
  end


  #
  # expose changed traceables
  # @param  reference_set [TraceableSet] the set of traceables used as reference
  # @param  category [Symbol] Restrict the operation to traceables of this category.
  #
  # @return [Array] List of trace_id which changed not in reference_set
  def changed_trace_ids(reference_set, category=nil)
    candidates=self.all_trace_ids(category) & reference_set.all_trace_ids(category)
    candidates.map{|candidate|
      self[candidate].get_diff(reference_set[candidate])
    }.compact
  end

  #
  # expose *unchanged* traceables
  # @param  reference_set [TraceableSet] the set of traceables used as reference
  # @param  category [Symbol] Restrict the operation to traceables of this category.
  #
  # @return [Array] List of trace_id which unchanged
  def unchanged_trace_ids(reference_set, category=nil)
    candidates=self.all_trace_ids(category) & reference_set.all_trace_ids(category)
    candidates.select{|candidate|
      self[candidate].get_diff(reference_set[candidate]).nil?
    }.compact
  end


  #
  # expose *deleted* traceables
  # @param  reference_set [TraceableSet] the set of traceables used as reference
  # @param  category [Symbol] Restrict the operation to traceables of this category.
  #
  # @return [Array] List of trace_id which are deleted (not in current set)
  def deleted_trace_ids(reference_set, category=nil)
    reference_set.all_trace_ids(category) - self.all_trace_ids(category)
  end


  # export the trace as graphml for yed
  # @return - the requirements tree in graphml
  def to_graphml
    f = File.open("#{File.dirname(__FILE__)}/../../resources/requirementsSynopsis.graphml")
    doc = Nokogiri::XML(f)
    f.close

    graph=doc.xpath("//xmlns:graph").first

    # generate all nodes
    self.all_traces(nil).each{|theTrace|
      n_node = Nokogiri::XML::Node.new "node", doc
      n_node["id"] = theTrace.id
      n_data = Nokogiri::XML::Node.new "data", doc
      n_data["key"]= "d6"
      n_ShapeNode = Nokogiri::XML::Node.new "y:ShapeNode", doc
      n_NodeLabel = Nokogiri::XML::Node.new "y:NodeLabel", doc
      n_NodeLabel.content = "[#{theTrace.id}] #{theTrace.header_orig}"
      n_ShapeNode << n_NodeLabel
      n_data << n_ShapeNode
      n_node << n_data
      graph << n_node

      theTrace.contributes_to.each{|up|
        n_edge=Nokogiri::XML::Node.new "edge", doc
        n_edge["source" ] = theTrace.id
        n_edge["target" ] = up
        n_edge["id"     ] = "#{up}_#{theTrace.id}"
        graph << n_edge
      }
    }
    xp(doc).to_xml
  end

  # this delivers an array ids of all Traceables
  # @param [Symbol] selected_category the category of the deisred Traceables
  #                 if nil is given, then all Traceables are returned
  # @return [Array of String] an array of the registered Traceables
  #                              of the selectedCategory
  def all_trace_ids(selected_category = nil)
    @traces.keys.select{|x|
      y = @traces[x].first
      selected_category.nil? or y.category == selected_category
    }.sort
  end

  #this delivers an array of all traces


  #
  # return an array of all traces of a given category
  # @param  selected_category [Symbol] the category of traceables to return
  #
  # @return [Array of Traceable] The array of traceables
  def all_traces(selected_category = nil)
    all_trace_ids(selected_category).map{|t| @traces[t].first}
  end


  #
  # return an array of all traces
  #
  # @return [Array of Traceable] array of all traces
  def all_traces_as_arrays
    @traces
  end

  # this returns a particular trace
  # in case of duplicates, it delivers the first one
  # @param id [String] the id of the requested traceable
  def [] (id)
    if @traces.has_key?(id)
      @traces[id].first
    else
      nil
    end
  end

  # this lists duplicate traces
  # @return [Array of String] the list of the id of duplicate Traces
  def duplicate_ids()
    @traces.select{|id, traceables| traceables.length > 1}.map{|id, traceable| id}.sort
  end

  # this lists duplicate traces
  # @return [Array of Traceable] the list duplicate Traces.
  def duplicate_traces()
    @traces.select{|id, traceables| traceables.length > 1}.map{|id, traceable| traceable}.sort
  end


  # this serializes a particular slot for caching
  # @param file [String] name of the cachefile
  def dump_to_marshal(file)
    File.open(file, "wb"){|f|
      Marshal.dump(self, f)
    }
  end

  # this loads cached information into a particular slot
  # @param file [String] name of the cachefile
  def  self.load_from_marshal(file)
    a=nil
    File.open(file, "rb"){|f| a=Marshal.load(f)}
    a
  end

  # this merges a TraceableSet
  # @return [Treaceable] the current traceable set
  def merge(set)
    set.all_traces_as_arrays.values.flatten.each{|t| self.add(t)}
  end

  # this retunrs traces marked as supported but not being defined
  # @return [Array of String] the list of the id of undefined Traces
  #         traces which are marked as uptraces but do not exist.
  def undefined_ids
    @supported_by.keys.select{|t| not @traces.has_key?(t)}.sort
  end

  #
  # returns the list of all uptraces in the current TraceableSet. Note that
  # this is a hash of strings.
  #
  #    myset.uptrace_ids[rs_foo_001]  # yield id of traces referring to rs_foo_001
  #
  # @return [Hash of Array of String] the Hash of the uptrace ids.
  def uptrace_ids
    @supported_by
  end

  # this adjusts the sortOrder
  # @param sort_order [Array of String ]  is an array of strings
  # if a traceId starts with such a string
  # it is placed according to the sequence
  # in the array. Otherwise it is sorted at the end
  def sort_order= (sort_order)
    @sort_order=sort_order
  end

  # this determines the sort order index of a trace
  # required behavior needs to be set in advance by the method sortOrder=
  # @param trace_id [String] the id of a Traceable for which
  #                 the sort order index shall be coumputed.
  # @return [String] the sort key of the given id.
  def trace_order_index(trace_id)
    global=@sort_order.index{|x| trace_id.start_with? x} ||
      (@sort_order.length+1)

    # add the {index} of the trace to
    orderId = [global.to_s.rjust(5,"0"),trace_id].join("_")
    orderId
  end

  # this delivers a string of traceables which can be used to compare
  # traces with a
  #


  #
  # return a string all traces sorted which can be saved as a file
  # and subsequently be used by a textual diff to determine changed
  # traces.
  #
  # @return [type] [description]
  def to_compareEntries
    all_traces.sort.map{|t| "\n\n[#{t.id}]\n#{t.as_oneline}" }.join("\n")
  end



  #############################

  private

  #
  # this is used to beautify an nokigiri document
  # @param [Nokogiri::XML::Document] doc - the document
  # @return [Nokogiri::XML::Document] the beautified document
  def xp(doc)
    xsl =<<XSL
    <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
    <xsl:strip-space elements="*"/>
    <xsl:template match="/">
    <xsl:copy-of select="."/>
    </xsl:template>
    </xsl:stylesheet>
XSL


    xslt = Nokogiri::XSLT(xsl)
    out  = xslt.transform(doc)

    out
  end


end




class Traceable
  include Comparable


  # String: The trace-Id
  attr_accessor :id
  # string: the alternative Id, used e.g. for the constraint number
  attr_accessor :alternative_id
  # String: The header in plain text
  attr_accessor :header_plain
  # String: The header in original format
  attr_accessor :header_orig
  # String: The body in plain text
  attr_accessor :body_plain
  # String: he body in original format
  attr_accessor :body_orig
  # Array of Strings: The uplink as an array of Trace-ids
  attr_accessor :contributes_to
  # String: the Traceable in its original format
  attr_accessor :trace_orig
  # String: origin of the entry
  attr_accessor :origin
  # String: category of the entry
  attr_accessor :category
  # String: info on the entry
  attr_accessor :info


  def initialize()
    @id = ""
    @alternative_id = ""
    @header_orig = ""
    @body_plain = ""
    @body_orig = ""
    @contributes_to = []
    @trace_orig = ""
    @category = ""
    @info = ""
  end

  # define the comparison to makeit really comaprable
  # @param [Traceable] other the other traceable for comparison.
  def <=> (other)
    @id <=> other.id
  end

  def get_diff(other)
    newval = self.get_comparison_string
    oldval = other.get_comparison_string

    #todo: get it back as soon as amatch is available
    similarity = "n/a"
    #similarity=newval.levenshtein_similar(oldval).to_s[0..6]

    if newval == oldval
      result = nil
    else
      diff_as_html= "<pre>#{other.trace_orig}</pre><hr/><pre>#{self.trace_orig}</pre>"#Diffy::Diff.new(other.trace_orig, self.trace_orig).to_s(:text)
      rawDiff = Diffy::Diff.new(self.trace_orig, other.trace_orig)
      diff_as_html=rawDiff.to_s(:html)

      result = [self.id, similarity, diff_as_html]
      diff_as_html=nil
    end
    result
  end


  def get_comparison_string
    "#{header_orig};#{body_orig};#{contributes_to.sort}".gsub(/\s+/," ")
  end

  def as_oneline
    trace_orig.gsub(/\s+/, " ")
  end


end
