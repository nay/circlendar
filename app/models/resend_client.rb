class ResendClient
  def self.send_batch(params_array)
    response = Resend::Batch.send(params_array)
    {
      data: response[:data],
      headers: response.respond_to?(:headers) ? response.headers : {}
    }
  end
end
