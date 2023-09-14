BEGIN;

select plan(3);

SELECT lives_ok($$
  CREATE TABLE events (
    device_id bigint,
    event_id bigserial,
    event_time timestamptz default now(),
    data jsonb not null,
    PRIMARY KEY (device_id, event_id)
  );
$$);

-- citus distributed test
SELECT lives_ok($$
  SELECT create_distributed_table('events', 'device_id');
$$);

-- citus columnar test
SELECT lives_ok($$
  CREATE TABLE events_columnar (
    device_id bigint,
    event_id bigserial,
    event_time timestamptz default now(),
    data jsonb not null
  )
  USING columnar;
$$);

SELECT * FROM finish();
ROLLBACK;
