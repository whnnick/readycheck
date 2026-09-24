# 0.1.107 acceptance

[中文](QA.zh-CN.md) | [Version index](../../VERSIONS.md) | [0.1.106 acceptance](../0.1.106/QA.md)

Local macOS preview. Public release has not been requested.

| Requirement | Status | Evidence |
| --- | --- | --- |
| Reduce unused space below display controls | Complete | Both display groups use a 135 pt minimum content height instead of 165 pt. In the installed macOS app, the Bubble layout keeps the controls and notch description clear while removing the excess bottom space. |
| Bubble and Card layouts | Complete | Visually checked both widget presentations in the installed 0.1.107 app. Card mode grows the left group to fit its extra controls; Bubble mode was restored afterward. |
| Regression | Complete | 197 Core tests and 4 App tests passed; Windows `npm run check`, release consistency, package build, and `git diff --check` passed. |
| Public release | Not requested | No GitHub push or Release requested. |
