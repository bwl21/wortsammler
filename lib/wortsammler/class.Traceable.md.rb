#
# this mixin represents the TeX specific methods of Traceable
#
#require 'ruby-debug' if not RUBY_PLATFORM=="i386-mingw32"
require 'treetop'
require File.dirname(__FILE__) + "/class.treetophelper"
require File.dirname(__FILE__) + "/class.Traceable"
require File.dirname(__FILE__) + "/class.Traceable.md"

Treetop.load File.dirname(__FILE__) + "/mdTraceParser.treetop"


class TraceableSet



  # this generates a synopsis of traces in markdown Format
  # @param [Symbol] selectedCategory the the category of the Traceables
  #                 which shall be reported.
  def reqtraceSynopsis(selectedCategory)
    all_traces(selectedCategory).
      sort_by{|x| trace_order_index(x.id) }.
    map{|t|
      tidm=t.id.gsub("_","-")

      lContributes=t.contributes_to.
      #                  map{|c| cm=c.gsub("_","-"); "[\[#{c}\]](#RT-#{cm})"}
      map{|c| cm=c.gsub("_","-"); "<a href=\"#RT-#{cm}\">\[#{c}\]</a>"}

      luptraces = [uptrace_ids[t.id]].flatten.compact.map{|x| self[x]}

      luptraces=luptraces.
      sort_by{|x| trace_order_index(x.id)}.
      map{|u|
        um = u.id.gsub("_","-")
        "    - <a href=\"#RT-#{um}\">[#{u.id}]</a> #{u.header_orig}"
      }

      ["- ->[#{t.id}] <!-- --> <a id=\"RT-#{tidm}\"/>**#{t.header_orig}**" +
       #                     "  (#{t.contributes_to.join(', ')})", "",
       "  (#{lContributes.join(', ')})", "",
       luptraces
       ].flatten.join("\n")
    }.join("\n\n")
  end


  # this generates the downstream_tracefile
  def to_downstream_tracefile(selectedCategory)
    all_traces(selectedCategory).
      sort_by{|x| trace_order_index(x.id) }.
    map{|t|
      "\n\n[#{t.id}] **#{t.header_orig}** { }()"
    }.join("\n\n")
  end

  #

  # This factory method processes all traces in a particular markdown file
  # and returns a TraceableSet
  #

  # @param  mdFile [String] name of the markdown File which shall be scanned

  #

  # @return [TraceableSet] The set of traceables found in the markdown file
  def self.processTracesInMdFile(mdFile)

    parser=TraceInMarkdownParser.new
    parser.consume_all_input = true

    raw_md_code_file=File.open(mdFile, "r:bom|utf-8")
    raw_md_code = raw_md_code_file.readlines.join
    raw_md_code_file.close
    #       print mdFile
    result = parser.parse(raw_md_code)
    #       print " ... parsed\n" todo: use logger here

    result_set = TraceableSet.new

    if result
      result.descendant.select{|x| x.getLabel==="trace"}.each{|c|
        id       = c.traceId.payload.text_value
        uptraces = c.uptraces.payload.text_value
        header   = c.traceHead.payload.text_value
        bodytext = c.traceBody.payload.text_value
        uptraces = c.uptraces.payload.text_value
        # Populate the Traceable entry
        theTrace = Traceable.new
        theTrace.info           = mdFile
        theTrace.id             = id
        theTrace.header_orig    = header
        theTrace.body_orig      = bodytext
        theTrace.trace_orig     = c.text_value
        theTrace.contributes_to = uptraces.gsub!(/\s*/, "").split(",")
        theTrace.category       = :SPECIFICATION_ITEM
        result_set.add(theTrace)
      }
      #            puts " .... finished"
    else
      puts ["","-----------", texFile, parser.failure_reason].join("\n")
    end
    result_set
  end


end
