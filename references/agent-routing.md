# Agency Agent Routing Index

178 agents in `~/.claude/agents/`, organized by division. Use the Agent tool with the agent file path to invoke.

## Quick Routing Table

| When user needs... | Division | Agent file |
|---------------------|----------|-----------|
| **Engineering** |
| Frontend (React/Vue/Angular) | engineering | `engineering-frontend-developer` |
| Backend architecture / API | engineering | `engineering-backend-architect` |
| Mobile app (iOS/Android/cross-platform) | engineering | `engineering-mobile-app-builder` |
| DevOps / CI/CD / infra | engineering | `engineering-devops-automator` |
| Security audit / threat model | engineering | `engineering-security-engineer` |
| Code review | engineering | `engineering-code-reviewer` |
| Database optimization | engineering | `engineering-database-optimizer` |
| AI/ML model development | engineering | `engineering-ai-engineer` |
| Data pipeline / lakehouse | engineering | `engineering-data-engineer` |
| Technical documentation | engineering | `engineering-technical-writer` |
| Rapid prototype / MVP | engineering | `engineering-rapid-prototyper` |
| Software architecture / DDD | engineering | `engineering-software-architect` |
| SRE / reliability / SLOs | engineering | `engineering-sre` |
| Incident response | engineering | `engineering-incident-response-commander` |
| Git workflow | engineering | `engineering-git-workflow-master` |
| Embedded / firmware / IoT | engineering | `engineering-embedded-firmware-engineer` |
| Solidity / smart contracts | engineering | `engineering-solidity-smart-contract-engineer` |
| WeChat mini-program | engineering | `engineering-wechat-mini-program-developer` |
| CMS (WordPress/Drupal) | engineering | `engineering-cms-developer` |
| **Design** |
| UI design / component library | design | `design-ui-designer` |
| UX research / usability testing | design | `design-ux-researcher` |
| UX architecture / CSS systems | design | `design-ux-architect` |
| Brand identity / guidelines | design | `design-brand-guardian` |
| Visual storytelling / multimedia | design | `design-visual-storyteller` |
| AI image prompts | design | `design-image-prompt-engineer` |
| Playful elements / personality | design | `design-whimsy-injector` |
| Inclusive / diverse visuals | design | `design-inclusive-visuals-specialist` |
| **Marketing** |
| Growth hacking / user acquisition | marketing | `marketing-growth-hacker` |
| SEO optimization | marketing | `marketing-seo-specialist` |
| Content creation / editorial | marketing | `marketing-content-creator` |
| Social media strategy | marketing | `marketing-social-media-strategist` |
| TikTok strategy | marketing | `marketing-tiktok-strategist` |
| Instagram marketing | marketing | `marketing-instagram-curator` |
| Twitter/X engagement | marketing | `marketing-twitter-engager` |
| LinkedIn content | marketing | `marketing-linkedin-content-creator` |
| Reddit community | marketing | `marketing-reddit-community-builder` |
| YouTube optimization | marketing | `marketing-video-optimization-specialist` |
| Podcast strategy | marketing | `marketing-podcast-strategist` |
| App Store (ASO) | marketing | `marketing-app-store-optimizer` |
| AI citation (AEO/GEO) | marketing | `marketing-ai-citation-strategist` |
| Book co-authoring | marketing | `marketing-book-co-author` |
| **China-specific marketing** |
| 小红书 (Xiaohongshu) | marketing | `marketing-xiaohongshu-specialist` |
| 抖音 (Douyin) | marketing | `marketing-douyin-strategist` |
| 快手 (Kuaishou) | marketing | `marketing-kuaishou-strategist` |
| 微信公众号 (WeChat OA) | marketing | `marketing-wechat-official-account` |
| 微博 (Weibo) | marketing | `marketing-weibo-strategist` |
| 知乎 (Zhihu) | marketing | `marketing-zhihu-strategist` |
| B站 (Bilibili) | marketing | `marketing-bilibili-content-strategist` |
| 百度SEO (Baidu) | marketing | `marketing-baidu-seo-specialist` |
| 中国电商 (Taobao/Tmall/PDD/JD) | marketing | `marketing-china-ecommerce-operator` |
| 跨境电商 (Amazon/Shopee/Lazada) | marketing | `marketing-cross-border-ecommerce` |
| 中国市场本地化 | marketing | `marketing-china-market-localization-strategist` |
| 直播带货 | marketing | `marketing-livestream-commerce-coach` |
| 短视频剪辑 (CapCut) | marketing | `marketing-short-video-editing-coach` |
| 私域运营 (WeCom/企业微信) | marketing | `marketing-private-domain-operator` |
| TikTok/IG carousel | marketing | `marketing-carousel-growth-engine` |
| **Paid Media** |
| PPC / Google Ads | paid-media | `paid-media-ppc-strategist` |
| Paid social (Meta/LinkedIn/TikTok) | paid-media | `paid-media-paid-social-strategist` |
| Ad creative / copy | paid-media | `paid-media-creative-strategist` |
| Conversion tracking / attribution | paid-media | `paid-media-tracking-specialist` |
| Campaign audit | paid-media | `paid-media-auditor` |
| Search query / negative keywords | paid-media | `paid-media-search-query-analyst` |
| Programmatic / display | paid-media | `paid-media-programmatic-buyer` |
| **Product** |
| Product management / lifecycle | product | `product-manager` |
| Sprint planning / prioritization | product | `product-sprint-prioritizer` |
| User feedback synthesis | product | `product-feedback-synthesizer` |
| Market trend research | product | `product-trend-researcher` |
| Behavioral nudge / UX psychology | product | `product-behavioral-nudge-engine` |
| **Project Management** |
| Project coordination / timelines | project-management | `project-management-project-shepherd` |
| Studio operations | project-management | `project-management-studio-operations` |
| Creative/tech production | project-management | `project-management-studio-producer` |
| Experiment tracking | project-management | `project-management-experiment-tracker` |
| Jira workflow | project-management | `project-management-jira-workflow-steward` |
| Senior PM / scope control | project-management | `project-manager-senior` |
| **Sales** |
| Outbound prospecting / sequences | sales | `sales-outbound-strategist` |
| Deal strategy / MEDDPICC | sales | `sales-deal-strategist` |
| Sales engineering / demo | sales | `sales-engineer` |
| Discovery coaching | sales | `sales-discovery-coach` |
| Sales team coaching | sales | `sales-coach` |
| Account expansion | sales | `sales-account-strategist` |
| Pipeline analytics | sales | `sales-pipeline-analyst` |
| Proposal / RFP | sales | `sales-proposal-strategist` |
| **Testing** |
| QA evidence / screenshots | testing | `testing-evidence-collector` |
| API testing | testing | `testing-api-tester` |
| Performance benchmarking | testing | `testing-performance-benchmarker` |
| Accessibility audit (WCAG) | testing | `testing-accessibility-auditor` |
| Workflow optimization | testing | `testing-workflow-optimizer` |
| Tool evaluation | testing | `testing-tool-evaluator` |
| Reality check / approval | testing | `testing-reality-checker` |
| Test results analysis | testing | `testing-test-results-analyzer` |
| **Support** |
| Customer support / tickets | support | `support-support-responder` |
| Business analytics / dashboards | support | `support-analytics-reporter` |
| Financial tracking / budgets | support | `support-finance-tracker` |
| Legal / compliance check | support | `support-legal-compliance-checker` |
| Infrastructure maintenance | support | `support-infrastructure-maintainer` |
| Executive summary / reports | support | `support-executive-summary-generator` |
| **Game Development** |
| Game design / mechanics / GDD | game-development | `game-designer` |
| Level design / pacing | game-development | `level-designer` |
| Narrative / dialogue / lore | game-development | `narrative-designer` |
| Game audio / FMOD/Wwise | game-development | `game-audio-engineer` |
| Shaders / VFX / art pipeline | game-development | `technical-artist` |
| **Spatial Computing** |
| visionOS / SwiftUI spatial | spatial-computing | `visionos-spatial-engineer` |
| WebXR / browser AR/VR | spatial-computing | `xr-immersive-developer` |
| XR interface / interaction | spatial-computing | `xr-interface-architect` |
| XR cockpit systems | spatial-computing | `xr-cockpit-interaction-specialist` |
| macOS Metal / 3D rendering | spatial-computing | `macos-spatial-metal-engineer` |
| **Academic** |
| Historical analysis | academic | `academic-historian` |
| Cultural anthropology | academic | `academic-anthropologist` |
| Psychology / behavior | academic | `academic-psychologist` |
| Geography / spatial analysis | academic | `academic-geographer` |
| Narrative / literary theory | academic | `academic-narratologist` |
| **Specialized** |
| Multi-agent orchestration | specialized | `agents-orchestrator` |
| MCP server development | specialized | `specialized-mcp-builder` |
| Blockchain audit | specialized | `specialized-blockchain-security-auditor` |
| Compliance (SOC2/ISO/HIPAA) | specialized | `compliance-auditor` |
| Document generation (PDF/PPTX/DOCX) | specialized | `specialized-document-generator` |
| Workflow architecture | specialized | `specialized-workflow-architect` |
| Developer advocacy | specialized | `specialized-developer-advocate` |
| Civil / structural engineering | specialized | `specialized-civil-engineer` |
| Study abroad planning | specialized | `study-abroad-advisor` |
| Zettelkasten / knowledge base | specialized | `zk-steward` |
| Recruitment / hiring (China) | specialized | `recruitment-specialist` |
| Corporate training design | specialized | `corporate-training-designer` |
