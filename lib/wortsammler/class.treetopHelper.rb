
#
# this mixin provides a convenient interface
# for the syntaxtree
#

class Treetop::Runtime::SyntaxNode
    
    # this delivers a child node of the AST
    def child
        elements.select{|e| e.is_ast?} if ! elements.nil?
    end
    
    # returns an array of all descendants of the current node
    # in the AST in document order
    def descendant
        child.map{|e| [e, e.descendant]}.flatten.compact if not child.nil?
    end
    
    # returns this and all descendant in document order
    def thisdescendant
        [self, descendant].flatten
    end
    
    # returns all nodes to up to the AST root
    def ancestor
        if ! parent.nil?
            [parent, parent.ancestor].flatten
        end
    end
    
    # indicates if the current treetop node is important enough
    # to be in the intended AST
    def is_ast?
        true # nonterminal? # parent.nil? or extension_modules.include?(Xmine)
    end
    
    # indicates if a meaningful name for the node in the AST
    # is available
    def has_rule_name?
        not (extension_modules.nil? or extension_modules.empty?)
    end
    
    # returns a meaning name for the node in the AST
    def rule_name
        if has_rule_name? then
            extension_modules.first.name.split("::").last.gsub(/[0-9]/,"")
            else
            "###"
        end
    end
    
    # another quick info for a node
    def to_info
        rule_name + ": "+ text_value
    end
    
    # exposes a node in the AST as xml
    def to_xml
        if child.nil? or child.empty?
            "#>" +interval.to_s + ":"+ text_value + "<#"
            else
            [  xml_start_tag,
            (child.nil? ? [] : child).map{|x| x.to_xml},
            xml_end_tag
            ].join
        end
    end
    
    # get the XML start tag
    def xml_start_tag
        if has_rule_name? then
            "<" + rule_name + ">"
        end
    end
    
    # get the XML end tag
    def xml_end_tag
        if has_rule_name? then
            "</" + rule_name + ">"
        end
    end
    
    # clean the tree by removing garbage nodes
    # which are not part of the intended AST
    def clean_tree(root_node)
        return if(root_node.elements.nil?)
        root_node.elements.delete_if{|node| not node.is_ast? }
        root_node.elements.each{|e| e.clean_tree(e)}
    end
end


class Treetop::Runtime::SyntaxNode
    def as_xml
        [(["<", getLabel, ">" ].join  if getLabel),
        (if elements
            elements.map { |e| e.as_xml }.join
            else
            text_value
        end),
        (["</", getLabel, ">" ].join  if getLabel)
        ].join
    end
    
    def wrap(tag,body)
        "<#{tag}>#{body}</#{tag}>"
    end
    
    def getLabel
        nil
    end
    
    
end


