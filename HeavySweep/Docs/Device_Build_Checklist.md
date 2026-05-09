# 真机打包配置清单

1. Xcode -> Signing & Capabilities
   - Team 选择公司开发者账号
   - Bundle ID 使用正式域名反向命名
2. Targets -> General
   - Version / Build 递增
   - Deployment Target 与设备覆盖策略一致
3. Archive
   - Product > Archive
   - Organizer 中 Validate App
4. Export
   - App Store Connect 上传
   - TestFlight 内测通过后再提审
