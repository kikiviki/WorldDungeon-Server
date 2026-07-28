-- 0021_starting_gear
--
-- A11 item 4 (back half): what a new character owns. Stock starting_items
-- (148 rows of per-city kits) is suppressed the 0017 way - tagged with a
-- content flag that stays disabled - because SetStartingItems
-- (common/shareddb.cpp) applies ContentFilterCriteria to the load. The rows
-- survive for a future PEQ refresh; they just never match.
--
-- TWO flags, opposite states:
--   wd_stock_starting_items  DISABLED - suppresses the stock kits
--   wd_universal_kit         ENABLED  - marks OUR rows. Needed because the
--     universal food/water rows would otherwise be shape-identical to stock's
--     (stock also grants 9991 with empty lists), leaving idempotent re-runs
--     no way to tell ours from stock's. Doubles as a kill switch.
--
-- New kit, universal (list value '0' = all; lists are pipe-separated):
--   * Bread Cakes* (9991) x20  - the stock newbie food
--   * Water Flask (13006) x20  - the stock newbie drink ("Water Flask*" does
--                                not exist; 13006 is the standard flask)
--   * one T0 morphing weapon form per class (0020), granted EQUIPPED in the
--     primary slot (inventory_slot 13). Class picks the starting FORM only -
--     all seven are all/all and the click script cycles freely:
--
--       1HB  Training Cudgel     CLR DRU SHM NEC WIZ MAG ENC
--       1HS  Training Blade      WAR PAL RNG SHK BRD
--       1HP  Training Dirk       ROG   (backstab hard-requires 1HP -
--                                       zone/special_attacks.cpp:724)
--       H2H  Training Wraps      MNK BST
--       2HS  Training Greatblade BER   (native 2H glass-cannon identity)
--
-- Class ids: WAR 1, CLR 2, PAL 3, RNG 4, SHD 5, DRU 6, MNK 7, BRD 8, ROG 9,
-- SHM 10, NEC 11, WIZ 12, MAG 13, ENC 14, BST 15, BER 16.
--
-- Idempotent: flags by DELETE+INSERT; the stock-tag UPDATE only touches empty
-- flags so it can never claim our rows; our rows are deleted by our flag.

DELETE FROM content_flags WHERE flag_name IN ('wd_stock_starting_items', 'wd_universal_kit');

INSERT INTO content_flags (flag_name, enabled, notes) VALUES
    ('wd_stock_starting_items', 0,
     'WD 0021: OFF replaces the stock per-city starting kits with the WD universal kit. Set 1 to restore stock starting items.'),
    ('wd_universal_kit', 1,
     'WD 0021: the WorldDungeon universal starting kit (food, water, T0 morphing weapon). Set 0 to disable.');

-- Our rows first (idempotent re-run), then tag the remaining untagged = stock.
DELETE FROM starting_items WHERE content_flags = 'wd_universal_kit';

UPDATE starting_items
   SET content_flags = 'wd_stock_starting_items'
 WHERE (content_flags IS NULL OR content_flags = '');

INSERT INTO starting_items
  (class_list, race_list, deity_list, zone_id_list, item_id, item_charges, inventory_slot, content_flags)
VALUES
  ('0',                   '0', '0', '0',    9991, 20, -1, 'wd_universal_kit'),  -- Bread Cakes* x20
  ('0',                   '0', '0', '0',   13006, 20, -1, 'wd_universal_kit'),  -- Water Flask x20
  ('2|6|10|11|12|13|14',  '0', '0', '0', 1001003,  1, 13, 'wd_universal_kit'),  -- Training Cudgel (1HB)
  ('1|3|4|5|8',           '0', '0', '0', 1001000,  1, 13, 'wd_universal_kit'),  -- Training Blade (1HS)
  ('9',                   '0', '0', '0', 1001002,  1, 13, 'wd_universal_kit'),  -- Training Dirk (1HP)
  ('7|15',                '0', '0', '0', 1001006,  1, 13, 'wd_universal_kit'),  -- Training Wraps (H2H)
  ('16',                  '0', '0', '0', 1001001,  1, 13, 'wd_universal_kit');  -- Training Greatblade (2HS)
