alias MastaniServer.CMS

# NOTE: seed order matters
CMS.seed_communities(:pl)
CMS.seed_communities(:framework)
CMS.seed_communities(:editor)
CMS.seed_communities(:design)
CMS.seed_communities(:database)
CMS.seed_communities(:devops)
CMS.seed_communities(:blockchain)
CMS.seed_communities(:city)
CMS.seed_communities(:home)

CMS.seed_set_category(["css"], "design")

CMS.seed_set_category(["iphone", "android"], "mobile")
CMS.seed_set_category(["ethereum", "bitcoin"], "blockchain")

CMS.seed_set_category(["tensorflow"], "ai")

CMS.seed_set_category(
  ["backbone", "d3", "react", "angular", "ionic", "meteor", "vue", "electron"],
  "frontend"
)

CMS.seed_set_category(
  [
    "django",
    "drupal",
    "eggjs",
    "nestjs",
    "laravel",
    "nodejs",
    "phoenix",
    "rails",
    "sails",
    "zend",
    "oracle",
    "hive",
    "cassandra",
    "elasticsearch",
    "sql-server",
    "neo4j",
    "mongodb",
    "mysql",
    "postgresql",
    "redis"
  ],
  "backend"
)