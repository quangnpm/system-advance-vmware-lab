# System Advance Lab tren VMware local

Repo mau de hoc chuoi GitHub -> Jenkins -> Ansible -> Docker Compose tren may VMware local. Toan bo workload chay tren cac VM Ubuntu trong ESXi/VMware Workstation; khong can AWS.

## Noi dung
- `app/`: web page nho de thay doi va nhan biet deploy.
- `Dockerfile`: build multi-stage, runtime Nginx nhe.
- `compose.yaml`: healthcheck va cong web 8080.
- `Jenkinsfile`: poll GitHub moi phut, validate, deploy qua Ansible.
- `ansible/`: inventory mau, playbook/role idempotent va collection requirements.
- `k8s/`: Deployment 2 replica va Service NodePort cho Kubernetes local.
- `docs/REPORT_GUIDE.md`: ghi chu thuyet trinh ngan.

## To chuc lab
Laptop Windows (VMware Workstation Pro) -> nested ESXi (tuy chon, chi dung hoc) -> VM Jenkins/Ansible va VM Docker target. Neu nested ESXi khong chay tren laptop, dung VMware Workstation tao truc tiep hai VM Ubuntu; phan pipeline van giong nhau. Nested ESXi tren Workstation la cau hinh lab, Broadcom khong ho tro cho production.

VM goi y: Jenkins/Ansible 2 vCPU, RAM 4 GB, dia 40 GB; Docker target 2 vCPU, RAM 2-4 GB, dia 25 GB. ESXi nested can them 2-4 vCPU, RAM 8 GB, dia 40 GB. Laptop nen co 16 GB RAM tro len; de chay ca Kubernetes multi-node can 24-32 GB hoac chay tung phase.

## 1. Chuan bi mang va may ao
1. Kiem tra BIOS/UEFI da bat Intel VT-x/AMD-V. Nested ESXi co the bi anh huong boi Hyper-V/VBS tren Windows; khong tat cac tinh nang bao mat Windows mot cach may moc. Neu ESXi VM bao khong thay virtualization, dung VM Ubuntu truc tiep tren Workstation va bo qua ESXi nested.
2. Trong Workstation tao mang Host-only (vi du VMnet1 192.168.56.0/24) de laptop truy cap VM; them NAT adapter rieng neu VM can Internet de cai package/image. Khong bridge lab ra mang cong cong.
3. (Tuy chon) Tao VM ESXi nested, bat "Expose hardware assisted virtualization to the guest OS", cai dat ESXi, dat IP quan ly co dinh. Trong ESXi tao port group cho mang lab va datastore tren disk ao.
4. Tao Ubuntu Server cho Jenkins va Docker target. Dat static IP hoac DHCP reservation, vi du `192.168.56.10` (jenkins) va `192.168.56.20` (target). Xac nhan ping va SSH giua hai VM.
5. Chup snapshot `clean-os` truoc khi cai dich vu; snapshot `lab-ready` sau khi hoan tat. Snapshot khong thay the backup.

## 2. Cai Docker target
Cai Docker Engine va Docker Compose plugin theo huong dan chinh thuc Docker cho Ubuntu. Them user `labdeploy` vao group docker chi tren may lab, sau do dang xuat/dang nhap lai. Docker socket co quyen gan root; chi dung user nay tren VM lab rieng.
```bash
docker version
docker compose version
sudo systemctl enable --now docker
```

## 3. Chuan bi Jenkins/Ansible VM
Cai Java duoc Jenkins LTS ho tro, Jenkins LTS, Git, Python 3, Ansible Core, OpenSSH client. Mo giao dien `http://192.168.56.10:8080`, hoan tat wizard, cai plugin Pipeline va Git. Khong expose cong 8080 ra Internet.

Tao SSH key rieng tren Jenkins agent/controller danh rieng cho lab. Dua public key vao `~/.ssh/authorized_keys` tren target. Them private key vao Jenkins Credentials voi ID `lab-target-key`, kind SSH Username with private key; khong commit private key. Playbook deploy vao home cua `labdeploy` va user nay can quyen truy cap Docker socket tren VM lab.

Trong Jenkins tao Pipeline job, set Definition = Pipeline script from SCM, SCM = Git, repo URL la HTTPS URL repo GitHub cua ban, branch `*/main`, Script Path `Jenkinsfile`. Pipeline poll SCM moi phut, vi laptop thuong khong co URL cong khai de GitHub webhook goi vao. Polling co tre toi khoang mot chu ky. Neu co endpoint HTTPS cong khai an toan, webhook `http(s)://<jenkins-public-url>/github-webhook/` la cach trigger nhanh hon; khong mo port router truc tiep cho lab.

## 4. Cau hinh job va inventory
Trong cau hinh Pipeline job, sua `TARGET_HOST` va `TARGET_USER` (mac dinh `192.168.56.20`, `labdeploy`) va credential SSH ID `lab-target-key`. Jenkinsfile tu tao inventory cho moi build. Tren Jenkins agent kiem tra SSH voi key va chay `ansible -i ansible/inventory.ini web -m ping` de xac nhan ket noi.

Tren Jenkins agent cai collection:
```bash
ansible-galaxy collection install -r ansible/requirements.yml
```

## 5. Chay lan dau va kiem chung
1. Push thu muc repo nay len GitHub cua ban (ten tai khoan trong anh la `quangnpm`). Tao repository moi va upload cac file nay; khong dua token/password/private key vao repo.
2. Chay job Jenkins thu cong lan dau. Xem console log: checkout -> validate -> cai Ansible collection -> deploy.
3. Mo `http://192.168.56.20:8080` va xac nhan trang. Kiem tra target: `docker compose -f /home/labdeploy/system-advance-lab/compose.yaml ps` va `docker inspect --format '{{.State.Health.Status}}' system-advance-web`.
4. Sua dong version trong `app/index.html` tu v1 thanh v2, commit va push. Trong 1-2 min Jenkins nen bat thay doi va deploy. Xac nhan trang web thay doi va build log bao thanh cong.
5. Chay lai job ma khong doi code. Ansible nen khong thay doi file; Compose module co the bao thay doi khi build phat sinh event. `ignore_build_events` giup tranh tinh build event rieng la thay doi neu collection ho tro.

## 6. Lo trinh Kubernetes local
Amazon EKS managed la dich vu AWS. Neu can thuc hanh khong AWS nhung van dung cong nghe EKS, AWS co EKS Anywhere cho ha tang tu quan ly, bao gom VMware vSphere; nhung can vSphere 7/8 co vCenter va tai nguyen lon (tai lieu yeu cau kha nang tao 6-10 VM, moi VM 2 vCPU/8 GB RAM/25 GB). Nested ESXi tren laptop thuong khong phu hop voi quy mo nay. Repo nay dung kind de hoc Kubernetes local nhe hon; day khong phai EKS Anywhere. Neu rubric bat buoc EKS Anywhere, can xac nhan du phan cung/vCenter va theo quy trinh rieng cua EKS Anywhere.

Tuy chon: de dung Kubernetes stage trong Jenkins, cai `kind` va `kubectl` tren Jenkins agent VM, tao cluster ten `lab` bang `kind create cluster --name lab`, sau do sua `ENABLE_K8S` trong Jenkinsfile thanh `true`. Stage se build image, nap vao kind, apply `k8s/` va doi rollout. De xem web tu laptop, chay `kubectl port-forward --address 0.0.0.0 service/system-advance-web 8081:80` tren Jenkins VM, gioi han firewall port 8081 vao mang Host-only, sau do mo `http://192.168.56.10:8081`. Stage Compose van deploy len target VM rieng.

## Troubleshooting nhanh
| Trieu chung | Kiem tra | Xu ly |
|---|---|---|
| Nested ESXi khong boot / khong thay VT-x | BIOS/UEFI, Workstation, Hyper-V/VBS va log VM | Dung VM Ubuntu truc tiep tren Workstation; khong can nested ESXi de demo pipeline. |
| Jenkins khong thay push | Build trigger, branch `main`, `pollSCM`, SCM URL, log polling | Chay Build Now, xem changelog/SCM; xac nhan job script path. |
| Ansible SSH fail | `ssh -vv`, IP, firewall, username, key credential | Sua IP/authorized_keys; khong tat host key checking trong moi truong that. |
| Permission denied voi Docker | `docker ps`, group, socket permission | Them `labdeploy` vao docker group cho VM lab va dang nhap lai; quyen nay gan nhu root. |
| Trang cu sau deploy | `docker compose ps`, health, build log, source duoc copy | Kiem tra Ansible copy path, Compose build context, refresh browser. |
| Healthcheck unhealthy | `docker inspect`, `docker logs`, URL/port | Dung `docker compose exec web wget -qO- http://127.0.0.1/`; sua endpoint/port. |

## Bao mat va don dep
Dung credential store cua Jenkins, SSH key rieng, host-only network, snapshot truoc thay doi lon va khong mo ESXi/Jenkins/Docker API ra Internet. Sau lab dung `docker compose down`, shutdown VM, xoa credential lab khi khong con can. Repo khong chua secret hay thong tin dang nhap.
