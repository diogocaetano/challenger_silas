class User

  attr_accessor :id, :followers

  def initialize(id)
    @id = id
    @followers = {}
  end

  def add_follower(user)
    @followers[user.id] = user
  end

  def remove_follower(user)
    @followers.delete user.id
  end

end
