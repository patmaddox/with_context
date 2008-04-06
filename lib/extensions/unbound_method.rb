class UnboundMethod
  def name
    to_s.split("#").last.delete(">")
  end
end
