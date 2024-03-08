---------------------------PROCEDURE---------------------------
set serveroutput on;

--Các thủ tục CRUD cho 1 bảng Danh mục/ Phân loại
--1. Thêm mới phân loại
CREATE OR REPLACE PROCEDURE THEM_PHAN_LOAI(
    p_id PHANLOAI.MAPL%TYPE,
    p_name PHANLOAI.TENPL%TYPE
)
IS
    v_count_id number;
    v_count_name number;
BEGIN
    select count(*) into v_count_id from phanloai where p_id = mapl;
    select count(*) into v_count_name from phanloai where p_name = tenpl;
    
    if v_count_id > 0 then
        dbms_output.put_line('Mã mới nhập đã được sử dụng!!!');
    elsif v_count_name > 0 then
        dbms_output.put_line('Tên mới nhập đã được sử dụng!!!');
    else
        INSERT INTO PHANLOAI VALUES (p_id, p_name);
        dbms_output.put_line('Danh mục đã được thêm mới.' || ' ' || p_id || ' ' || p_name);
    end if;
END;

select * from phanloai order by mapl desc;

delete phanloai
where mapl = 'PL006';

--insert sai
exec THEM_PHAN_LOAI('PL001', 'OK');
exec THEM_PHAN_LOAI('PL006', 'Phòng làm việc');
--insert đúng
exec THEM_PHAN_LOAI('PL005', 'OK');

--2. Xuất ra thông tin danh mục
CREATE OR REPLACE PROCEDURE XUAT_THONG_TIN(
    p_name PHANLOAI.TENPL%TYPE
)
IS
    v_name PHANLOAI.TENPL%TYPE;
BEGIN
    SELECT UPPER(tenpl) INTO v_name FROM phanloai where tenpl like p_name;
    dbms_output.put_line('Tên danh mục: ' || p_name);
    EXCEPTION
    WHEN no_data_found THEN
        dbms_output.put_line('Không tìm thấy danh mục');
END;

--tìm kiếm có kết quả
exec XUAT_THONG_TIN('Phòng làm việc');
--tìm kiếm không có kết quả
exec XUAT_THONG_TIN('Phòng tắm');

--3. Cập nhật thông tin
CREATE OR REPLACE PROCEDURE CAP_NHAT_DANH_MUC(
    p_id PHANLOAI.MAPL%TYPE,
    p_name PHANLOAI.TENPL%TYPE
)
IS
    v_count number;
    v_count_name number;
BEGIN
    select count(*) into v_count 
    from phanloai 
    where p_id = mapl;
    
    select count(*) into v_count_name
    from phanloai
    where p_name = tenpl;
    
    if v_count = 0 then 
        dbms_output.put_line('Không tồn tại mã phân loại!!!');
    elsif v_count_name > 0 then
        dbms_output.put_line('Danh mục không được giống!!!');
    else
        UPDATE phanloai 
        SET tenpl = p_name 
        WHERE mapl = p_id;
        dbms_output.put_line('Danh mục đã được cập nhật.');
    end if;
    EXCEPTION
    WHEN others THEN
        dbms_output.put_line('Lỗi khi cập nhật danh mục.');
        ROLLBACK;
END;

select * from phanloai;

--update đúng
exec CAP_NHAT_DANH_MUC('PL003', 'A');
exec CAP_NHAT_DANH_MUC('PL003', 'Phòng ngủ');
--update sai
exec CAP_NHAT_DANH_MUC('PL005', 'Phòng tắm');
exec CAP_NHAT_DANH_MUC('PL003', 'Phòng bếp');


--4. Xóa thông tin
CREATE OR REPLACE PROCEDURE XOA_PHAN_LOAI(
    p_id PHANLOAI.MAPL%TYPE
)
IS
    v_count number;
BEGIN
    select count(*) into v_count 
    from phanloai 
    where p_id = mapl;
    if v_count > 0 then
        DELETE FROM phanloai WHERE mapl = p_id;
        dbms_output.put_line('Danh mục đã được xóa.');
    else
        dbms_output.put_line('Lỗi khi xóa danh mục.');
    end if;
END;

--xóa đúng
exec XOA_PHAN_LOAI('PL005');
--xóa sai
exec XOA_PHAN_LOAI('PL001');


--Các thủ tục liên quan đến nghiệp vụ (vd: Lập đơn đặt hàng, Xử lý Thanh toán hóa đơn, …)
--1. Nhập thông tin đơn hàng, kiểm tra tính hợp lệ của thông tin, lưu trữ đơn hàng mới vào cơ sở dữ liệu.
CREATE OR REPLACE PROCEDURE THEM_HOA_DON(
    p_BillId HOADON.MAHD%TYPE,
    p_daycreated HOADON.NGAYTAOHD%TYPE,
    p_EmpId HOADON.MANV%TYPE,
    p_CusId HOADON.MAKH%TYPE,
    p_ProId CTHD.MASP%TYPE,
    p_Amount CTHD.SLMUA%TYPE
)
IS
    v_count number;
BEGIN
    IF p_BillId IS NULL OR p_daycreated IS NULL OR p_EmpId IS NULL OR p_CusId IS NULL OR p_ProId IS NULL OR p_Amount IS NULL THEN    
        dbms_output.put_line('Vui lòng điền đầy đủ thông tin đơn hàng!!!');
    ELSE
        SELECT COUNT(*)
        INTO v_count
        FROM HOADON
        WHERE MAHD = p_BillId;
        
        IF v_count > 0 THEN
            dbms_output.put_line('Mã hóa đơn đã tồn tại!!!');
        ELSE
            SELECT COUNT(*)
            INTO v_count
            FROM NHANVIEN
            WHERE MANV = p_EmpId;

            IF v_count = 0 THEN
                dbms_output.put_line('Mã nhân viên không tồn tại!!!');
            ELSE
                SELECT COUNT(*)
                INTO v_count
                FROM KHACHHANG
                WHERE MAKH = p_CusId;

                IF v_count = 0 THEN
                    dbms_output.put_line('Mã khách hàng không tồn tại!!!');
                ELSE
                    SELECT COUNT(*)
                    INTO v_count
                    FROM SANPHAM
                    WHERE MASP = p_ProId;

                    IF v_count = 0 THEN
                        dbms_output.put_line('Mã sản phẩm không tồn tại!!!');
                    ELSIF p_Amount IS NULL or p_Amount <= 0 THEN
                        dbms_output.put_line('Hãy nhập số lượng mua!!!');
                    ELSE
                        INSERT INTO HOADON (MAHD, NGAYTAOHD, MANV, MAKH)
                        VALUES (p_BillId, p_daycreated, p_EmpId, p_CusId);
                        
                        INSERT INTO CTHD (MASP, MAHD, SLMUA)
                        VALUES (p_ProId, p_BillId, p_Amount);
                        
                        dbms_output.put_line('Thêm đơn hàng thành công!!!');
                    END IF;
                END IF;
            END IF;
        END IF;
    END IF;
    EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Có lỗi xảy ra khi thực thi thủ tục!!!');
END;

select * from hoadon order by mahd;
select * from cthd order by mahd;

--insert sai
exec THEM_HOA_DON('HD999', SYSDATE, 'NV010', 'KH002', 'SP001', 0);
--insert đúng
exec THEM_HOA_DON('HD999', SYSDATE, 'NV010', 'KH002', 'SP001', 1);



/* --2. Xử lý tình trạng thanh toán. Thêm các cột NOIGIAO, NGAYGIAO, TINHTRANGTT vào trong bảng CTHD
TH1: Nếu nơi giao là tại quầy thì để tình trạng là "đã thanh toán".
TH2: Nếu nơi giao là địa chỉ khác và chưa đến nơi giao thì để là "chưa thanh toán". 
TH3: Nếu đến nơi giao thì tình trạng thanh toán đổi thành "đã thanh toán".*/
alter table CTHD
add NOIGIAO nvarchar2(300);

alter table CTHD
add NGAYGIAO date;

alter table CTHD
add TINHTRANGTT nvarchar2(50);

select * from CTHD;

CREATE OR REPLACE PROCEDURE Xu_Ly_Tinh_Trang_TT (
        p_BillId CTHD.MAHD%TYPE,
        p_DeliAdd CTHD.NOIGIAO%TYPE,
        p_DayDelivered CTHD.NGAYGIAO%TYPE,
        p_PayStatus CTHD.TINHTRANGTT%TYPE
)
IS
    v_count number;
BEGIN
    select count(*) into v_count from cthd where p_BillId = mahd;
    if v_count > 0 then
        IF p_DeliAdd = 'Tại quầy' then
            UPDATE CTHD
            set NOIGIAO = 'Tại quầy', NGAYGIAO = sysdate, TINHTRANGTT = 'Thanh toán'
            where p_BillId = MAHD;
            dbms_output.put_line(p_BillId || ' ' || p_DeliAdd || ' ' || p_DayDelivered || ' ' || p_PayStatus);
        ELSIF p_DeliAdd != 'Tại quầy' and p_DeliAdd is not null and p_DayDelivered is null then
            UPDATE CTHD
            set NOIGIAO = p_DeliAdd, NGAYGIAO = null, TINHTRANGTT = 'Chưa'
            where p_BillId = MAHD;
            dbms_output.put_line(p_BillId || ' ' || p_DeliAdd || ' ' || p_DayDelivered || ' ' || p_PayStatus);
        ELSIF p_DeliAdd != 'Tại quầy' and p_DeliAdd is not null and p_DayDelivered is not null then
            UPDATE CTHD
            set NOIGIAO = p_DeliAdd, NGAYGIAO = sysdate, TINHTRANGTT = 'Đã thanh toán'
            where p_BillId = MAHD;
            dbms_output.put_line(p_BillId || ' ' || p_DeliAdd || ' ' || p_DayDelivered || ' ' || p_PayStatus);
        ELSE
            dbms_output.put_line('Hãy nhập đầy đủ thông tin!!!');
        END IF;
    else dbms_output.put_line('Không tồn tại hóa đơn này!!!');
    end if;
END;

select * from cthd order by mahd;

--update TH1
exec Xu_Ly_Tinh_Trang_TT('HD001', 'Tại quầy', '', '');
--update TH2
exec Xu_Ly_Tinh_Trang_TT('HD001', 'Củ Chi', '', '');
--update TH3
exec Xu_Ly_Tinh_Trang_TT('HD001', 'Củ Chi', sysdate, '');
--update sai
exec Xu_Ly_Tinh_Trang_TT('HD999', '', '', '');


--Các thủ tục kết xuất báo cáo định kỳ
--1. Nhập vào ngày để xem tổng doanh thu của ngày đó
CREATE OR REPLACE PROCEDURE xuat_doanh_thu (
    p_day_created hoadon.ngaytaohd%TYPE
) IS
    v_exists_day NUMBER := 0;
BEGIN
    select count(*) into v_exists_day
    from hoadon
    where ngaytaohd = p_day_created;
    if v_exists_day > 0 then
        FOR revenue_record IN (
            SELECT SUM((cthd.slmua * sanpham.giaban) - (cthd.slmua * sanpham.giaban * loaikh.chietkhau)) AS total_amount
            FROM
                cthd,
                hoadon,
                sanpham,
                khachhang,
                loaikh
            WHERE
                    cthd.mahd = hoadon.mahd
                AND cthd.masp = sanpham.masp
                AND khachhang.maloaikh = loaikh.maloaikh
                AND khachhang.makh = hoadon.makh
                AND ngaytaohd = p_day_created
        ) LOOP
            dbms_output.put_line(revenue_record.total_amount);
        END LOOP;
    else
       dbms_output.put_line('Không có dữ liệu về ngày ' || p_day_created);
    end if;
END;

--test không có dữ liệu về ngày này
exec xuat_doanh_thu(DATE '2024-1-3');
--test có dữ liệu về ngày này
exec xuat_doanh_thu(DATE '2024-1-1');


--2. Nhập vào tên thành phố và ngày để xem doanh thu nơi nào là cao nhất tại thời điểm đó
CREATE OR REPLACE PROCEDURE xuat_doanh_thu_dia_chi (
    p_day_created hoadon.ngaytaohd%TYPE,
    p_diachi      khachhang.diachi%TYPE
) IS
    v_total_amount NUMBER;
    v_exists_day NUMBER := 0;
    v_exists_place NUMBER := 0;
BEGIN
    SELECT COUNT(*) INTO v_exists_day 
    FROM hoadon 
    WHERE ngaytaohd = p_day_created;
    
    SELECT COUNT(*) INTO v_exists_place 
    FROM khachhang 
    WHERE diachi LIKE p_diachi;
    
    SELECT SUM((cthd.slmua * sanpham.giaban) - (cthd.slmua * sanpham.giaban * loaikh.chietkhau))
    INTO v_total_amount
    FROM cthd,hoadon,sanpham,khachhang,loaikh
    WHERE cthd.mahd = hoadon.mahd
          AND cthd.masp = sanpham.masp
          AND khachhang.maloaikh = loaikh.maloaikh
          AND khachhang.makh = hoadon.makh
          AND ngaytaohd = p_day_created
          AND khachhang.diachi LIKE p_diachi;
    
    IF v_exists_day = 0 THEN
        dbms_output.put_line('Không có dữ liệu liên quan về ngày' || ' ' || p_day_created || '!!!');
    ELSIF v_exists_place = 0 or v_total_amount is null THEN
        dbms_output.put_line('Không có dữ liệu liên quan về' || ' ' || p_diachi || '!!!');
    ELSE
        dbms_output.put_line('Tổng số tiền trong ngày '|| p_day_created || ' tại ' || p_diachi || ' là: ' || v_total_amount);
    END IF;
END;

--test không có dữ liệu vào ngày nhập
exec xuat_doanh_thu_dia_chi(date '2024-1-3', '%Hồ_Chí_Minh%');
--test không có dữ liệu ở nơi này
exec xuat_doanh_thu_dia_chi(date '2024-1-2', '%Bình_Dương%');
--test có dữ liệu
exec xuat_doanh_thu_dia_chi(date '2024-1-2', '%Hồ_Chí_Minh%');


--3. Nhập vào mã loại khách hàng, xem có bao nhiêu khách hàng thuộc vào loại khách hàng mình nhập
CREATE OR REPLACE PROCEDURE xuat_khach_hang (
    p_MALOAIKH loaikh.maloaikh%TYPE
) IS
    v_count_maloaikh number;
    v_total_amount_cus NUMBER;
BEGIN
    select count(*) into v_count_maloaikh from khachhang where maloaikh = p_MALOAIKH;
    IF v_count_maloaikh > 0 then
        select count(*) into v_total_amount_cus
        from khachhang
        left join loaikh 
        on khachhang.maloaikh = loaikh.maloaikh
        where khachhang.maloaikh = p_MALOAIKH;
        dbms_output.put_line(p_MALOAIKH||': '||v_total_amount_cus);
    else
        dbms_output.put_line('Không có loại khách hàng này!!!');
    END IF;
END;
--test đúng
exec xuat_khach_hang('CD');
--test sai
exec xuat_khach_hang('AN');