module Utils
  def humanize(str)
    str.tr('_', ' ')
  end; module_function :humanize

  def pluralize(str)
    "#{str}s"
  end; module_function :pluralize
end
