/*
-------------------------------------
-------------------------------------
WE CREATE THE DATABASE AND EXTENTIONS
-------------------------------------
-------------------------------------
*/
CREATE EXTENSION DBLINK;
CREATE DATABASE biblioteca;
CREATE DATABASE facultad_ingenieriaYCienciasBasicas;
CREATE DATABASE facultad_CienciasDeLaComunicacion;
/*
-----------------------------------------------------
-----------------------------------------------------
WE CREATE THE TABLES IN EACH DATABASE OF THE FACULTYS
-----------------------------------------------------
-----------------------------------------------------
*/
set search_path = Public;
CREATE TABLE sede(
	id_sede integer NOT NULL  ,
	dir_sede VARCHAR(255) NOT NULL,
	nam_sede VARCHAR(255) NOT NULL  ,
	CONSTRAINT sede_pk PRIMARY KEY (id_sede)
);
CREATE TABLE facultad (
	id_facul integer NOT NULL  ,
	decano VARCHAR(255),
	nam_facul VARCHAR(255) NOT NULL  ,
	CONSTRAINT facultad_pk PRIMARY KEY (id_facul)
);
CREATE TABLE carrera (
	id_carr integer NOT NULL  ,
	nam_carr VARCHAR(255) NOT NULL,
	coordinador VARCHAR(255) NOT NULL  ,
	id_facul INTEGER NOT NULL  ,
	CONSTRAINT carrera_pk PRIMARY KEY (id_facul ,id_carr)
);
CREATE TABLE estudiante (
	id_est serial NOT NULL  ,
	nam_est VARCHAR(255) NOT NULL,
	fechanac DATE NOT NULL,
	cel integer NOT NULL  ,
	estado BOOLEAN,
	CONSTRAINT estudiante_pk PRIMARY KEY (id_est)
);
CREATE TABLE profesor (
	id_profesor serial NOT NULL  ,
	profesion VARCHAR(255) NOT NULL,
	nam_prof VARCHAR(255) NOT NULL,
	id_facul integer NOT NULL,
    id_grupo integer NOT NULL  ,
    id_asig integer NOT NULL  ,
	CONSTRAINT profesor_pk PRIMARY KEY (id_profesor)
);
CREATE TABLE asignaturas (
	id_asig integer NOT NULL  ,
	int_hor integer NOT NULL  ,
	creditos integer NOT NULL,
	nam_asig VARCHAR(255) NOT NULL  ,
	CONSTRAINT asignaturas_pk PRIMARY KEY (id_asig)
);
CREATE TABLE grupo (
	id_grupo integer NOT NULL  ,
	id_profesor integer NOT NULL,	
	id_asig integer NOT NULL  ,
    horario VARCHAR(255) NOT NULL,
	CONSTRAINT imparte_pk PRIMARY KEY (id_grupo,id_asig)
);
CREATE TABLE inscribe (
	id_est integer NOT NULL  ,
	id_grupo integer NOT NULL  ,
    id_asig integer NOT NULL  ,
	n1 FLOAT,
	n2 FLOAT,
	n3 FLOAT,
	CONSTRAINT inscribe_pk PRIMARY KEY (id_est,id_grupo)
);
CREATE TABLE matricula (
	id_est integer NOT NULL  ,
	id_carr integer NOT NULL  ,
    id_facul INTEGER NOT NULL  ,
    
	CONSTRAINT matricula_pk PRIMARY KEY (id_est,id_carr)
);
CREATE TABLE salon (
	id_salon integer NOT NULL  ,
	tipo_salon VARCHAR(255) NOT NULL  ,
	capacidad integer NOT NULL,
	id_sede integer NOT NULL  ,
    id_grupo integer NOT NULL,
    id_asig integer NOT NULL  ,
	CONSTRAINT salon_pk PRIMARY KEY (id_sede,id_salon)
);

ALTER TABLE carrera ADD CONSTRAINT carrera_fk0 FOREIGN KEY (id_facul) REFERENCES facultad(id_facul);

ALTER TABLE profesor ADD CONSTRAINT profesor_fk0 FOREIGN KEY (id_facul) REFERENCES facultad(id_facul);
ALTER TABLE profesor ADD CONSTRAINT profesor_fk1 FOREIGN KEY (id_grupo,id_asig) REFERENCES grupo(id_grupo,id_asig);

ALTER TABLE grupo ADD CONSTRAINT imparte_fk0 FOREIGN KEY (id_profesor) REFERENCES profesor(id_profesor);
ALTER TABLE grupo ADD CONSTRAINT imparte_fk1 FOREIGN KEY (id_asig) REFERENCES asignaturas(id_asig);

ALTER TABLE inscribe ADD CONSTRAINT inscribe_fk0 FOREIGN KEY (id_est) REFERENCES estudiante(id_est);
ALTER TABLE inscribe ADD CONSTRAINT inscribe_fk1 FOREIGN KEY (id_grupo,id_asig ) REFERENCES grupo(id_grupo,id_asig);

ALTER TABLE matricula ADD CONSTRAINT matricula_fk0 FOREIGN KEY (id_est) REFERENCES estudiante(id_est);
ALTER TABLE matricula ADD CONSTRAINT matricula_fk1 FOREIGN KEY (id_facul ,id_carr) REFERENCES carrera(id_facul ,id_carr);

ALTER TABLE salon ADD CONSTRAINT salon_fk0 FOREIGN KEY (id_sede) REFERENCES sede(id_sede);
ALTER TABLE salon ADD CONSTRAINT salon_fk1 FOREIGN KEY (id_grupo,id_asig) REFERENCES grupo(id_grupo,id_asig);
/*
--------------------------------------
--------------------------------------
WE CREATE THE TABLES OF THE BIBLIBRARY
--------------------------------------
--------------------------------------
*/
CREATE TABLE prestamo (
	id_prestamo serial NOT NULL  ,
    id_est integer NOT NULL  ,
	fechaprestamo DATE NOT NULL,
	fechadevolucion DATE NOT NULL,
    duracionprestamo integer NOT NULL,
	id_libros integer NOT NULL  ,
    id_ejemplar integer NOT NULL  ,
	CONSTRAINT prestamo_pk PRIMARY KEY (id_est,id_libros,id_ejemplar,id_prestamo)
);

CREATE TABLE libros (
	id_libros integer NOT NULL  ,
	editorial VARCHAR(255) NOT NULL,
	titulo VARCHAR(255) NOT NULL,
	edicion VARCHAR(255) NOT NULL,
	autor TEXT NOT NULL,
	CONSTRAINT libros_pk PRIMARY KEY (id_libros)
);

CREATE TABLE ejemplares (
	id_ejemplar integer NOT NULL  ,
	version1 VARCHAR(255) NOT NULL,
	id_libros integer NOT NULL  ,
	CONSTRAINT ejemplares_pk PRIMARY KEY (id_libros,id_ejemplar)
);

ALTER TABLE ejemplares ADD CONSTRAINT ejemplares_fk0 FOREIGN KEY (id_libros) REFERENCES libros(id_libros);
ALTER TABLE prestamo ADD CONSTRAINT prestamo_fk2 FOREIGN KEY (id_libros,id_ejemplar) REFERENCES ejemplares(id_libros,id_ejemplar);
/* 
--------------------------------------
--------------------------------------
WE CREATE THE ROLES AND THE GRANT PERMISS AND VIEW
--------------------------------------
--------------------------------------
*/
CREATE ROLE coordinador;
CREATE ROLE profesor;
CREATE ROLE estudiante;
CREATE ROLE bibliotecario;
CREATE USER "estudianteConsulta" WITH LOGIN PASSWORD 'M1cr0s0ft';
CREATE USER "profesorConsulta" WITH LOGIN PASSWORD 'M1cr0s0ft';
CREATE USER "bibliotecarioConsulta" WITH LOGIN PASSWORD 'M1cr0s0ft';
GRANT estudiante TO "estudianteConsulta";
GRANT profesor TO "profesorConsulta";

---------------------------LIBRIAN VIEW-------------------------------------
CREATE VIEW EstudiantesUniversidad AS
SELECT estudiantecomuni.id_est, estudiantecomuni.nam_est, estudiantecomuni.estado 
FROM dblink('dbname = facultad_cienciasdelacomunicacion port = 5432 user = "bibliotecarioConsulta" password = 'M1cr0s0ft'',
'SELECT id_est, nam_est, estado FROM estudiante')AS estudiantecomuni(id_est INTEGER,nam_est VARCHAR,estado BOOLEAN)
UNION
SELECT estudianteinge.id_est, estudianteinge.nam_est, estudianteinge.estado 
FROM dblink('dbname = facultad_ingenieriaycienciasbasicas port = 5432 user = "bibliotecarioConsulta" password = 'M1cr0s0ft' ',
'SELECT id_est, nam_est, estado FROM estudiante')AS estudianteinge(id_est INTEGER,nam_est VARCHAR,estado BOOLEAN);

----------------------------STUDENTS VIEW----------------------------------
CREATE VIEW estudiantesNotas AS 
SELECT est.nam_est,asig.nam_asig, ins.n1, ins.n2, ins.n3, ((n1*0.3)+(n2*0.3)+(n3*0.4))AS def FROM inscribe AS ins
INNER JOIN estudiante AS est ON ins.id_est = est.id_est
INNER JOIN grupo AS gr ON gr.id_grupo = ins.id_grupo
INNER JOIN asignaturas AS asig ON asig.id_asig = gr.id_asig
WHERE est.id_est :: TEXT = CURRENT_USER;
/*
!REVISAR VISTA YA QUE PIDE USUARIO Y PASSWORD Y DEBERIA SER LIBRE
*/
CREATE VIEW librosBiblioteca AS
SELECT titulo, autor FROM dblink('dbname = biblioteca port = 5432 user = "estudianteConsulta" password = 'M1cr0s0ft'','SELECT titulo, autor FROM libros') 
					AS libros(titulo VARCHAR, autor TEXT);

CREATE VIEW prestamosEstudiantes AS
SELECT est.nam_est,lib.titulo,lib.autor,prestamo.fechaprestamo, prestamo.fechadevolucion FROM dblink('dbname = biblioteca port = 5432',
					'SELECT fechaprestamo, fechadevolucion, id_est, id_libro FROM prestamo')AS prestamo(
					fechaprestamo DATE, fechadevolucion DATE, id_est INTEGER, id_libro INTEGER)
INNER JOIN estudiante AS est ON prestamo.id_est = est.id_est
INNER JOIN (SELECT id_libros ,titulo,autor FROM dblink('dbname = biblioteca port = 5432 user = "estudianteConsulta" password = 'M1cr0s0ft'',
										'SELECT id_libros, titulo, autor FROM libros')AS libros(id_libros INTEGER, titulo VARCHAR, autor VARCHAR)) AS lib ON prestamo.id_libro = lib.id_libros
WHERE est.id_est :: TEXT = CURRENT_USER;
---------------------------- COORDINATOR VIEWS--------------------------------
CREATE VIEW coordinadorEstudiantes AS 
SELECT est.id_est, est.nam_est, est.cel,carr.nam_carr FROM estudiante AS est
INNER JOIN matricula AS mat ON  mat.id_est = est.id_est
INNER JOIN carrera AS carr ON mat.id_carr = carr.id_carr;

---------------------------- TEACHER VIEWS------------------------------------
CREATE VIEW profesorNotas AS
SELECT est.nam_est, asig.nam_asig, gr.id_grupo, ins.n1, ins.n2, ins.n3, ((n1*0.3)+(n2*0.3)+(n3*0.4))AS def FROM inscribe AS ins
INNER JOIN estudiante AS est ON ins.id_est = est.id_est
INNER JOIN grupo AS gr ON gr.id_grupo = ins.id_grupo
INNER JOIN asignaturas AS asig ON asig.id_asig = gr.id_asig
INNER JOIN profesor AS pro ON pro.id_profesor = gr.id_profesor
WHERE pro.id_profesor :: TEXT = CURRENT_USER;
/*
!REVISAR VISTA YA QUE PIDE USUARIO Y PASSWORD Y DEBERIA SER LIBRE
*/
CREATE VIEW librosBiblioteca AS
SELECT titulo, autor FROM dblink('dbname = biblioteca port = 5432 user = "profesorConsulta" password = 'M1cr0s0ft'','SELECT titulo, autor FROM libros') 
					AS libros(titulo VARCHAR, autor TEXT);

----------------------------LIBRARIAN PERMISS----------------------------------
GRANT CONNECT ON DATABASE biblioteca TO bibliotecario;
GRANT CONNECT ON DATABASE facultad_ingenieriaYCienciasBasicas TO bibliotecario;
GRANT CONNECT ON DATABASE facultad_CienciasDeLaComunicacion TO bibliotecario;
GRANT INSERT , UPDATE, DELETE ON TABLE prestamo TO bibliotecario;
GRANT INSERT , UPDATE, DELETE ON TABLE ejemplares TO bibliotecario;
GRANT INSERT , UPDATE, DELETE ON TABLE libros TO bibliotecario;
GRANT SELECT ON EstudiantesUniversidad TO bibliotecario;

----------------------------COORDINATOR PERMISS----------------------------
GRANT CONNECT ON DATABASE facultad_ingenieriaYCienciasBasicas TO coordinador;
GRANT USAGE ON SCHEMA public TO coordinador;
GRANT INSERT , UPDATE, DELETE ON TABLE estudiante, grupo TO coordinador;
GRANT UPDATE ON TABLE inscribe TO coordinador;
GRANT CONNECT ON DATABASE facultad_CienciasDeLaComunicacion TO coordinador;
GRANT USAGE ON SCHEMA public TO coordinador;
GRANT INSERT , UPDATE, DELETE ON TABLE estudiante, grupo TO coordinador;
GRANT UPDATE ON TABLE inscribe TO coordinador;
GRANT SELECT ON coordinadorEstudiantes TO coordinador;

----------------------------TEACHER PERMISS----------------------------
GRANT CONNECT ON DATABASE facultad_ingenieriaYCienciasBasicas TO profesor;
GRANT USAGE ON SCHEMA public TO profesor;
GRANT INSERT, UPDATE ON TABLE inscribe TO profesor;
GRANT CONNECT ON DATABASE facultad_CienciasDeLaComunicacion TO profesor;
GRANT USAGE ON SCHEMA public TO profesor;
GRANT INSERT, UPDATE ON TABLE inscribe TO profesor;
GRANT SELECT ON profesorNotas TO profesor;
GRANT SELECT ON librosBiblioteca TO profesor;
----------------------------STUDENTS PERMISS----------------------------
GRANT CONNECT ON DATABASE facultad_ingenieriaYCienciasBasicas TO estudiante;
GRANT USAGE ON SCHEMA public TO estudiante;
GRANT CONNECT ON DATABASE facultad_CienciasDeLaComunicacion TO estudiante;
GRANT USAGE ON SCHEMA public TO estudiante;
GRANT SELECT ON estudiantesNotas TO estudiante;
GRANT SELECT ON librosBiblioteca TO estudiante;
GRANT SELECT ON prestamosEstudiantes TO estudiante;
