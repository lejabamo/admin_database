

-- Tabla de huéspedes
CREATE TABLE guests (
    guest_id integer PRIMARY KEY,
    first_name varchar(100) NOT NULL,
    last_name varchar(100) NOT NULL,
    email varchar(255) NOT NULL,
    phone varchar(20),
    country varchar(100) NOT NULL,
    date_of_birth date NOT NULL,
    loyalty_tier varchar(20) NOT NULL,
    registration_date timestamp NOT NULL,
    last_visit timestamp
);

-- Tabla de habitaciones
CREATE TABLE rooms (
    room_id integer PRIMARY KEY,
    room_number varchar(10) NOT NULL,
    room_type varchar(50) NOT NULL,
    floor integer NOT NULL,
    capacity integer NOT NULL,
    base_price numeric(10,2) NOT NULL,
    has_sea_view boolean NOT NULL,
    has_balcony boolean NOT NULL,
    amenities text[]
);

-- Tabla de reservas
CREATE TABLE reservations (
    reservation_id integer PRIMARY KEY,
    guest_id integer NOT NULL,
    room_id integer NOT NULL,
    check_in_date timestamp NOT NULL,
    check_out_date timestamp NOT NULL,
    adults integer NOT NULL,
    children integer NOT NULL,
    total_amount numeric(10,2) NOT NULL,
    status varchar(20) NOT NULL,
    created_at timestamp NOT NULL,
    special_requests text
);

-- Tabla de servicios del hotel
CREATE TABLE hotel_services (
    service_id integer PRIMARY KEY,
    service_name varchar(100) NOT NULL,
    category varchar(50) NOT NULL,
    price numeric(8,2) NOT NULL,
    duration_minutes integer,
    available_time_start time,
    available_time_end time
);

-- Tabla de consumo de servicios
CREATE TABLE service_consumption (
    consumption_id integer PRIMARY KEY,
    reservation_id integer NOT NULL,
    service_id integer NOT NULL,
    guest_id integer NOT NULL,
    consumption_time timestamp NOT NULL,
    quantity integer NOT NULL DEFAULT 1,
    total_cost numeric(8,2) NOT NULL
);

-- Insertar datos de huéspedes
INSERT INTO guests VALUES
(1, 'Ana', 'García', 'ana.garcia@email.com', '+34-600-111-222', 'Spain', '1985-03-15', 'Gold', '2020-05-10 14:30:00', '2024-01-15 10:00:00'),
(2, 'John', 'Smith', 'john.smith@email.com', '+1-555-0101', 'USA', '1978-07-22', 'Platinum', '2019-11-20 09:15:00', '2024-02-20 16:45:00'),
(3, 'Marie', 'Dubois', 'marie.dubois@email.com', '+33-1-2345-678', 'France', '1990-12-03', 'Silver', '2021-03-05 11:20:00', '2024-01-30 12:30:00'),
(4, 'Carlos', 'Rodríguez', 'carlos.rod@email.com', '+34-600-333-444', 'Spain', '1982-08-18', 'Gold', '2020-08-12 16:00:00', '2024-02-10 14:15:00'),
(5, 'Sarah', 'Johnson', 'sarah.j@email.com', '+44-20-7946-0958', 'UK', '1975-04-30', 'Platinum', '2018-06-25 10:45:00', '2024-02-25 09:00:00'),
(6, 'Luca', 'Rossi', 'luca.rossi@email.com', '+39-02-1234-567', 'Italy', '1988-11-12', 'Silver', '2022-01-15 13:10:00', '2024-01-20 17:30:00'),
(7, 'Elena', 'Martínez', 'elena.m@email.com', '+34-600-555-666', 'Spain', '1993-06-08', 'Bronze', '2023-02-28 08:30:00', '2024-02-05 11:45:00'),
(8, 'Robert', 'Brown', 'robert.b@email.com', '+1-555-0202', 'USA', '1965-09-25', 'Platinum', '2017-09-08 15:20:00', '2024-01-10 13:00:00');

-- Insertar datos de habitaciones
INSERT INTO rooms VALUES
(1, '101', 'Standard', 1, 2, 120.00, false, false, '{"WiFi","TV","AC"}'),
(2, '102', 'Standard', 1, 2, 120.00, false, true, '{"WiFi","TV","AC"}'),
(3, '201', 'Deluxe', 2, 3, 200.00, true, true, '{"WiFi","TV","AC","Minibar","Safe"}'),
(4, '202', 'Deluxe', 2, 3, 200.00, true, true, '{"WiFi","TV","AC","Minibar","Safe"}'),
(5, '301', 'Suite', 3, 4, 350.00, true, true, '{"WiFi","TV","AC","Minibar","Safe","Jacuzzi"}'),
(6, '302', 'Suite', 3, 4, 350.00, true, true, '{"WiFi","TV","AC","Minibar","Safe","Jacuzzi"}'),
(7, '103', 'Standard', 1, 2, 120.00, false, false, '{"WiFi","TV","AC"}'),
(8, '203', 'Deluxe', 2, 3, 200.00, false, true, '{"WiFi","TV","AC","Minibar","Safe"}');

-- Insertar datos de reservas
INSERT INTO reservations VALUES
(1, 1, 3, '2024-01-10 15:00:00', '2024-01-15 11:00:00', 2, 1, 1000.00, 'completed', '2023-12-15 10:30:00', 'Late check-in requested'),
(2, 2, 5, '2024-02-18 14:00:00', '2024-02-25 10:00:00', 2, 2, 2450.00, 'confirmed', '2024-01-20 16:45:00', 'Anniversary celebration'),
(3, 3, 2, '2024-01-28 16:00:00', '2024-01-30 12:00:00', 1, 0, 240.00, 'completed', '2024-01-10 11:20:00', NULL),
(4, 4, 4, '2024-02-08 13:00:00', '2024-02-12 11:00:00', 2, 0, 800.00, 'completed', '2024-01-25 14:15:00', 'Sea view preferred'),
(5, 5, 6, '2024-02-23 15:00:00', '2024-03-01 10:00:00', 2, 1, 2100.00, 'confirmed', '2024-02-01 09:00:00', 'High floor requested'),
(6, 6, 1, '2024-01-18 12:00:00', '2024-01-22 10:00:00', 2, 0, 480.00, 'completed', '2023-12-20 13:10:00', NULL),
(7, 7, 7, '2024-02-03 14:00:00', '2024-02-07 11:00:00', 1, 0, 480.00, 'completed', '2024-01-15 08:30:00', 'Quiet room please'),
(8, 8, 8, '2024-01-08 16:00:00', '2024-01-12 10:00:00', 2, 0, 800.00, 'completed', '2023-12-28 15:20:00', NULL);

-- Insertar datos de servicios
INSERT INTO hotel_services VALUES
(1, 'Spa Massage', 'Wellness', 80.00, 60, '09:00', '20:00'),
(2, 'Breakfast Buffet', 'Dining', 25.00, NULL, '07:00', '11:00'),
(3, 'Airport Transfer', 'Transport', 50.00, 30, '00:00', '23:59'),
(4, 'Room Service', 'Dining', 15.00, NULL, '06:00', '23:00'),
(5, 'Fitness Center', 'Recreation', 0.00, NULL, '06:00', '22:00'),
(6, 'Swimming Pool', 'Recreation', 0.00, NULL, '08:00', '20:00'),
(7, 'Business Center', 'Business', 0.00, NULL, '00:00', '23:59'),
(8, 'Laundry Service', 'Housekeeping', 20.00, 120, '08:00', '18:00');

-- Insertar datos de consumo de servicios
INSERT INTO service_consumption VALUES
(1, 1, 2, 1, '2024-01-11 08:30:00', 3, 75.00),
(2, 1, 1, 1, '2024-01-12 16:00:00', 1, 80.00),
(3, 2, 3, 2, '2024-02-18 10:00:00', 1, 50.00),
(4, 2, 2, 2, '2024-02-19 09:15:00', 4, 100.00),
(5, 3, 4, 3, '2024-01-29 20:30:00', 1, 15.00),
(6, 4, 1, 4, '2024-02-09 18:00:00', 2, 160.00),
(7, 5, 8, 5, '2024-02-24 09:00:00', 1, 20.00),
(8, 6, 2, 6, '2024-01-19 08:00:00', 2, 50.00);

-- CREAR ÍNDICES PARA OPTIMIZACIÓN
-- Índices B-tree básicos
CREATE INDEX idx_guests_last_name ON guests(last_name);
CREATE INDEX idx_guests_country ON guests(country);
CREATE INDEX idx_guests_loyalty_tier ON guests(loyalty_tier);
CREATE INDEX idx_rooms_room_type ON rooms(room_type);
CREATE INDEX idx_rooms_floor ON rooms(floor);
CREATE INDEX idx_reservations_status ON reservations(status);
CREATE INDEX idx_reservations_guest_id ON reservations(guest_id);
CREATE INDEX idx_reservations_room_id ON reservations(room_id);

-- Índices compuestos
CREATE INDEX idx_guests_name_country ON guests(last_name, first_name, country);
CREATE INDEX idx_reservations_dates_status ON reservations(check_in_date, check_out_date, status);
CREATE INDEX idx_rooms_type_view ON rooms(room_type, has_sea_view, base_price);

-- Índices funcionales con EXTRACT
CREATE INDEX idx_reservations_checkin_year ON reservations(EXTRACT(YEAR FROM check_in_date));
CREATE INDEX idx_reservations_checkin_month ON reservations(EXTRACT(MONTH FROM check_in_date));
CREATE INDEX idx_reservations_checkin_dow ON reservations(EXTRACT(DOW FROM check_in_date));
CREATE INDEX idx_reservations_checkin_hour ON reservations(EXTRACT(HOUR FROM check_in_date));

CREATE INDEX idx_guests_birth_month ON guests(EXTRACT(MONTH FROM date_of_birth));
CREATE INDEX idx_guests_registration_year ON guests(EXTRACT(YEAR FROM registration_date));

CREATE INDEX idx_consumption_time_hour ON service_consumption(EXTRACT(HOUR FROM consumption_time));
CREATE INDEX idx_consumption_time_dow ON service_consumption(EXTRACT(DOW FROM consumption_time));

-- Índices parciales
CREATE INDEX idx_guests_platinum ON guests(guest_id, loyalty_tier) WHERE loyalty_tier = 'Platinum';
CREATE INDEX idx_rooms_sea_view ON rooms(room_id, base_price) WHERE has_sea_view = true;
CREATE INDEX idx_reservations_active ON reservations(reservation_id, guest_id) WHERE status IN ('confirmed', 'checked-in');
CREATE INDEX idx_services_paid ON hotel_services(service_id, price) WHERE price > 0;

-- Índices de expresión avanzados
CREATE INDEX idx_guests_email_domain ON guests(SUBSTRING(email FROM '@(.*)$'));
CREATE INDEX idx_guests_full_name_lower ON guests(LOWER(last_name || ' ' || first_name));
CREATE INDEX idx_reservations_stay_duration ON reservations((EXTRACT(EPOCH FROM (check_out_date - check_in_date))/86400));

-- Índices para arrays (PostgreSQL específico)
CREATE INDEX idx_rooms_amenities ON rooms USING GIN (amenities);

-- Índices para texto completo
CREATE INDEX idx_reservations_special_requests ON reservations USING GIN (to_tsvector('english', special_requests));