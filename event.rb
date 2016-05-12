class Event

  attr_reader :seq, :type, :from, :to, :payload

  def initialize(payload)
    @payload = payload
    parse payload
  end

  private

  def parse(payload)
    elements = payload.split '|'

    valid = true

    seq_element = elements[0]
    seq_number = seq_element.to_i

    type_element = elements[1]
    if type_element == 'F'
      type = :follow
    elsif type_element == 'U'
      type = :unfollow
    elsif type_element == 'B'
      type = :broadcast
    elsif type_element == 'P'
      type = :private_message
    else type_element == 'S'
      type = :status_update
    end

    if type == :status_update
      from = elements[2]
    elsif type != :broadcast
      from = elements[2]
      to = elements[3]
    end

    @seq = seq_number
    @type = type
    @from = from
    @to = to
  end
end
