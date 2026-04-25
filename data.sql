-- 1. Création de la table des Écoles (Etablissements)
CREATE TABLE IF NOT EXISTS ecole (
    id SERIAL PRIMARY KEY,
    nom TEXT NOT NULL,
    adresse TEXT,
    telephone TEXT,
    email TEXT,
    ville TEXT,
    pays TEXT DEFAULT 'Guinée',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Création de la table des Licences
CREATE TABLE IF NOT EXISTS licence (
    id SERIAL PRIMARY KEY,
    key TEXT UNIQUE NOT NULL,      -- La clé de 24 caractères
    id_ecole INTEGER REFERENCES ecole(id),
    active BOOLEAN DEFAULT FALSE,  -- Est-ce que la licence est activée ?
    device_id TEXT,               -- L'identifiant unique de la machine (lié lors de l'activation)
    activated_at TIMESTAMP,        -- Date de l'activation
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- 3. Création de la table des Utilisateurs (Sécurité)
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insertion de l'utilisateur par défaut
INSERT INTO users (username, password) 
VALUES ('samkale', '1121SS1121')
ON CONFLICT (username) DO NOTHING;
