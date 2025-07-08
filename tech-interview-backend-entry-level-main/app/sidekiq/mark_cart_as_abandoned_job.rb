class MarkCartAsAbandonedJob
  include Sidekiq::Job

  def perform
    # Marca como abandonados os carrinhos sem interação há mais de 3 horas
    Cart.where("updated_at < ? AND abandoned = ?", 3.hours.ago, false).find_each do |cart|
      cart.mark_as_abandoned!
    end

    # Remove carrinhos abandonados há mais de 7 dias
    Cart.where("abandoned = ? AND updated_at < ?", true, 7.days.ago).find_each do |cart|
      cart.remove_if_abandoned!
    end
  end
end
