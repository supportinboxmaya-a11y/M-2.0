import os


class LearnerConfig:
    ENABLED = os.getenv("LEARNER_ENABLED", "false").lower() == "true"
    SEARCH_MODEL = os.getenv("LEARNER_SEARCH_MODEL", "qwen2.5:7b")
    EXEC_MODEL = os.getenv("LEARNER_EXEC_MODEL", "qwen2.5:7b")
    MAX_SEARCH_RESULTS = int(os.getenv("LEARNER_MAX_RESULTS", "5"))
    MAX_SCRAPE_LENGTH = int(os.getenv("LEARNER_MAX_SCRAPE", "8000"))
    SANDBOX_TIMEOUT = int(os.getenv("LEARNER_SANDBOX_TIMEOUT", "30"))
    CRAWL_DELAY = float(os.getenv("LEARNER_CRAWL_DELAY", "1.5"))
    AUTO_DISTILL = os.getenv("LEARNER_AUTO_DISTILL", "true").lower() == "true"
    REQUIRE_APPROVAL = os.getenv("LEARNER_REQUIRE_APPROVAL", "true").lower() == "true"
    KNOWLEDGE_DB = os.getenv("LEARNER_KNOWLEDGE_DB", "storage/learner_knowledge.db")