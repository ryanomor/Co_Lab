DROP DATABASE IF EXISTS co_lab;
CREATE DATABASE co_lab;

\c co_lab;

DROP TABLE IF EXISTS users;
CREATE TABLE users (
  user_ID SERIAL PRIMARY KEY,
  email VARCHAR,
  firstname VARCHAR,
  lastname VARCHAR,
  username VARCHAR UNIQUE,
  password_digest VARCHAR,
  profile_pic VARCHAR
);

CREATE TABLE projects (
  project_ID SERIAL PRIMARY KEY,
  project_name VARCHAR,
  project_description VARCHAR,
  skill_tags VARCHAR,
  creator INTEGER REFERENCES users(user_id)
);

CREATE TABLE collaborations (
  collaboration_ID SERIAL PRIMARY KEY,
  project_ID INTEGER REFERENCES projects,
  user_ID INTEGER REFERENCES users
);

-- INSERT INTO users (username, password_digest, user_bio)
--   VALUES ('Tyler', '$2a$10$brAZfSmByFeZmPZ/MH5zne9YDhugjW9CtsBGgXqGfix0g1tcooZWq', 'My name is Tyler I like swimming'),
--          ('Taylor', '$2a$10$brAZfSmByFeZmPZ/MH5zne9YDhugjW9CtsBGgXqGfix0g1tcooZWq', 'My name is Taylor and I like swimming'),
--          ('Chancellor', '$2a$10$brAZfSmByFeZmPZ/MH5zne9YDhugjW9CtsBGgXqGfix0g1tcooZWq', 'rapping'),
--          ('Victoria', '$2a$10$brAZfSmByFeZmPZ/MH5zne9YDhugjW9CtsBGgXqGfix0g1tcooZWq', 'gymnastics'),
--          ('Josephine', '$2a$10$brAZfSmByFeZmPZ/MH5zne9YDhugjW9CtsBGgXqGfix0g1tcooZWq', 'cooking'),
--          ('Keith', '$2a$10$brAZfSmByFeZmPZ/MH5zne9YDhugjW9CtsBGgXqGfix0g1tcooZWq', 'gaming'),
--          ('Ben', '$2a$10$brAZfSmByFeZmPZ/MH5zne9YDhugjW9CtsBGgXqGfix0g1tcooZWq', 'drawing'),
--          ('Stephen', '$2a$10$brAZfSmByFeZmPZ/MH5zne9YDhugjW9CtsBGgXqGfix0g1tcooZWq', 'basketball'),
--          ('Kim', '$2a$10$brAZfSmByFeZmPZ/MH5zne9YDhugjW9CtsBGgXqGfix0g1tcooZWq', 'singing'),
--          ('fart', '$2a$10$noryJFgByFccCS/F6XILSeqM.3TqBhmRJ0QtAMPHtlzriqk6rsY8S', 'I enjoy farting around, when I can I try to fart as much as I can');
         
-- INSERT INTO images (user_ID, img_URL)
--   VALUES (5, 'https://www.finetunedfinances.com/2018/01/12/long-weekend/'),
--          (3, 'https://in.pinterest.com/explore/instagram-photo-ideas/'),
--          (7, 'https://www.collabary.com/blog/break-the-instagram-how-to-capture-and-create-the-perfect-influencer-photo/'),
--          (2, 'https://weheartit.com/entry/141387101'),
--          (7, 'https://weheartit.com/entry/271048874'),
--          (9, 'http://blog.artifacia.com/the-ultimate-guide-to-instagram-photos-for-brands/'),
--          (10, 'http://theblacksheeponline.com/wp-content/uploads/2016/12/boooode.jpg'),
--          (10, 'http://i0.kym-cdn.com/entries/icons/facebook/000/011/220/24219235.jpg'),
--          (10, 'https://images.baklol.com/The-Struggle-is-Real0728943671499686396.jpg');
