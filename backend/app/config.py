from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    supabase_url: str
    supabase_anon_key: str
    supabase_service_role_key: str
    google_api_key: str
    app_secret: str

    # gemini-2.0-flash has its own separate free-tier quota counter.
    # 1500 req/day is more than enough for the 4-agent pipeline.
    gemini_model: str = "gemini-2.5-flash"
    model_classifier: str = "gemini-2.5-flash"
    model_auditor: str = "gemini-2.5-flash"
    model_vendor_intel: str = "gemini-2.5-flash"
    model_drafter: str = "gemini-2.5-flash"

    log_level: str = "INFO"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )


settings = Settings()