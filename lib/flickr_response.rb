module FlickRaw
class Response
  def to_hash
    hash = {}
    @h.each {|k,v|
      hash[k] = case v
        when FlickRaw::Response then v.to_hash
        when FlickRaw::ResponseList then v.to_a.collect {|e| e.to_hash}
        else v
      end
    }
    hash
  end
end
end