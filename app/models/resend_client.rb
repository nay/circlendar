class ResendClient
  def self.send_batch(params_array)
    response = Resend::Batch.send(params_array)
    data = response[:data]
    # Resend gem only symbolizes top-level keys; nested hashes retain string keys
    data = data.map { |r| r.transform_keys(&:to_sym) } if data.is_a?(Array)
    {
      data: data || [],
      headers: response.respond_to?(:headers) ? response.headers : {}
    }
  end
end
