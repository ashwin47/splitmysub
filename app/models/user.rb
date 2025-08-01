class User < ApplicationRecord
  include CurrencySupport

  has_many :sessions, dependent: :destroy

  # SplitMySub associations
  has_many :projects, dependent: :destroy
  has_many :project_memberships, dependent: :destroy
  has_many :member_projects, through: :project_memberships, source: :project
  has_many :payments, dependent: :destroy
  has_many :magic_links, dependent: :destroy
  has_many :telegram_messages, dependent: :destroy

  # Serialize preferences as JSON
  serialize :preferences, coder: JSON

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  validates :email_address, presence: true, uniqueness: { case_sensitive: false }, format: {
    with: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i,
    message: "must be a valid email address"
  }
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :telegram_user_id, uniqueness: { allow_blank: true }
  validates :telegram_verification_token, uniqueness: { allow_blank: true }

  # Scopes for common queries
  scope :with_projects, -> { joins(:projects).distinct }
  scope :with_memberships, -> { joins(:project_memberships).distinct }

  # Business logic methods
  def full_name
    "#{first_name} #{last_name}".strip
  end

  def owned_projects
    projects
  end

  def all_projects
    Project.joins("LEFT JOIN project_memberships ON projects.id = project_memberships.project_id")
           .where("projects.user_id = ? OR project_memberships.user_id = ?", id, id)
           .distinct
  end

  # Currency preference methods
  def default_currency
    preferred_currency || "USD"
  end

  def format_currency(amount, currency_code = nil)
    currency_code ||= default_currency
    locale = self.class.currency_locale(currency_code) || "en-US"
    symbol = self.class.currency_symbol(currency_code) || "$"

    return "0.00" if amount.nil?

    case currency_code
    when "JPY", "KRW", "VND", "IDR"
      # These currencies typically don't use decimal places
      "#{symbol}#{amount.to_i}"
    else
      formatted_amount = sprintf("%.2f", amount)
      "#{symbol}#{formatted_amount}"
    end
  end

  # Telegram-related methods
  def telegram_linked?
    telegram_user_id.present?
  end

  def telegram_notifications_enabled?
    telegram_notifications_enabled == true
  end

  def generate_telegram_verification_token
    token = SecureRandom.hex(16)
    update!(
      telegram_verification_token: token,
      telegram_verification_token_expires_at: 30.minutes.from_now
    )
    token
  end

  def telegram_verification_token_valid?
    telegram_verification_token.present? &&
      telegram_verification_token_expires_at.present? &&
      telegram_verification_token_expires_at > Time.current
  end

  def unlink_telegram_account!
    update!(
      telegram_user_id: nil,
      telegram_username: nil,
      telegram_verification_token: nil,
      telegram_verification_token_expires_at: nil
    )
  end

  def toggle_telegram_notifications!
    update!(telegram_notifications_enabled: !telegram_notifications_enabled?)
  end
end
