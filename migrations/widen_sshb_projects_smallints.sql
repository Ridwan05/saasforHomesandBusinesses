-- Widen sshb_projects.jdacost and sshb_projects.connections from smallint to bigint.
-- smallint maxes out at 32767, but jdacost is a Naira amount and connections is a
-- planned household count — both routinely exceed that ceiling. UPSERTs were failing
-- with: 22003 "value \"<n>\" is out of range for type smallint".
-- Run in Supabase Dashboard › SQL Editor.

alter table public.sshb_projects
  alter column jdacost     type bigint using jdacost::bigint,
  alter column connections type bigint using connections::bigint;
