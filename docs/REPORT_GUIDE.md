# Ghi chu thuyet trinh

1. **Muc tieu:** mo phong quy trinh van hanh he thong tu VM den container va CI/CD tren laptop, khong phu thuoc AWS.
2. **Luồng:** push GitHub -> Jenkins poll SCM -> validate -> Ansible SSH -> copy source -> Docker Compose build/reconcile -> healthcheck.
3. **ESXi:** VM, port group/mang lab, datastore, snapshot; neu dung ESXi nested thi chi la lab khong duoc Broadcom ho tro production.
4. **Ansible idempotence:** task mo ta trang thai mong muon; copy chi changed khi noi dung doi; Compose state present chi tao/reconcile container can thiet. Chay lai playbook de chung minh.
5. **Docker:** multi-stage tach buoc kiem tra noi dung va runtime Nginx; Compose cong 8080, restart policy, healthcheck.
6. **Kubernetes:** EKS la AWS. Tren local thay bang kind/minikube; giai thich day la local Kubernetes, khong phai EKS.
7. **Demo:** sua v1 thanh v2, push, theo doi Jenkins console va mo lai trang web; sau do deploy lai khong doi code de noi ve idempotence.
8. **Chuan doan:** phan loai loi theo Git trigger, Jenkins stage, SSH/Ansible, Docker build, Compose/health va network.

## Cau hoi co the duoc hoi
- **Tai sao Jenkins polling?** Jenkins local sau NAT khong co URL cong khai de GitHub webhook ket noi; polling don gian va an toan hon cho lab. Webhook la lua chon neu co endpoint HTTPS co the truy cap.
- **Ansible va Docker lam gi khac nhau?** Ansible cau hinh/deploy tu xa; Docker dong goi va chay ung dung.
- **Snapshot co phai backup?** Khong. Snapshot huu ich rollback ngan han, nhung van phu thuoc datastore va host.
- **Tai sao khong goi day la EKS?** EKS la dich vu AWS quan ly control plane. Cluster kind/minikube tren laptop la Kubernetes local.
