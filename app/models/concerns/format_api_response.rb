module FormatApiResponse
  include ActiveResource::Formats::JsonFormat
  attr_accessor :meta

  extend self

  def encode(hash = nil, options = nil)
    ActiveSupport::JSON.encode(hash, options)
  end

  def decode(json)
    _meta = ActiveSupport::JSON.decode(json)['meta']
    @data = ActiveSupport::JSON.decode(json)['data']
    @meta = arranged_meta(_meta) if _meta
    arranged_collection(@data) if @data
  end

  private

  def arranged_collection(collection)
    if collection.is_a? Array
      arranged = []
      collection.each do |col|
        arranged << col["attributes"]
      end
    else
      arranged = collection['attributes']
    end
    arranged
  end

  def arranged_meta(meta)
    facets = {}
    aggs = meta["facets"]
    pagination = meta["pagination"].transform_keys(&:to_sym)
    if aggs
      aggs.keys.each do |k|
        facets[k.to_sym] = aggs[k]["buckets"].map { |f| f.transform_keys(&:to_sym) }
      end
    end
    arranged = { facets: facets, pagination: pagination}
  end
end
