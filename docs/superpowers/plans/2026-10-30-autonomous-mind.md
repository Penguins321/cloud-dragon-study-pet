# Autonomous Companion Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans and verification-before-completion.

**Goal:** Continuous simulated needs and bounded AI episodes drive companion actions.
**Architecture:** RefCounted mind per role; existing scheduler supplies cadence, brain supplies validated optional follow-up plans, existing local control retains priority.
**Spec:** docs/superpowers/specs/2026-10-30-autonomous-mind.md

- [x] Add failing test for autonomous_mind, implement energy/curiosity/social state and weighted fallback; pure tests pass.
- [x] Extend brain metadata and decision protocol with bounded intent/plan; core tests cover whitelisting, duplicate rejection and schema compatibility.
- [x] Integrate observation, per-role state, local plan execution and interrupt behavior; expose concise intention in settings.
- [x] Real DeepSeek test: action look with 2 follow-ups; ordinary chat/preference recall remain valid.
- [x] Full regression, independent review and exported application smoke.
- [x] Rebuild launcher target, update documentation, commit and push.

追加点击与模拟作息已实现；新增缺失作息测试先失败后通过。最终完整回归 exit 0，真实鼠标 smoke 通过，新增原生计划/点击用例通过。独立审查无阻塞问题，导出运行通过。
