import {
  pgTable,
  uuid,
  varchar,
  boolean,
  smallint,
  text,
  jsonb,
  timestamp,
  unique,
  check,
} from 'drizzle-orm/pg-core'
import { relations, sql } from 'drizzle-orm'

// ---- Banks ----

export const banks = pgTable('banks', {
  id:        uuid('id').primaryKey().defaultRandom(),
  code:      varchar('code', { length: 10 }).unique().notNull(),
  name:      varchar('name', { length: 100 }).notNull(),
  shortName: varchar('short_name', { length: 20 }).notNull(),
  isActive:  boolean('is_active').default(true).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
})

// ---- CNAB Layouts ----

export const cnabLayouts = pgTable('cnab_layouts', {
  id:         uuid('id').primaryKey().defaultRandom(),
  bankId:     uuid('bank_id').notNull().references(() => banks.id, { onDelete: 'restrict' }),
  format:     varchar('format', { length: 30 }).notNull(),    // 'CNAB240' | 'CNAB400' | 'CNAB400_REMESSA' | 'CNAB400_RETORNO' | 'CNAB240_COBRANCA_REM' | 'CNAB240_COBRANCA_RET'
  version:    varchar('version', { length: 20 }).notNull(),
  name:       varchar('name', { length: 150 }).notNull(),
  lineLength: smallint('line_length').notNull(),               // 240 | 400
  encoding:   varchar('encoding', { length: 20 }).default('latin1').notNull(),
  isActive:   boolean('is_active').default(true).notNull(),
  notes:      text('notes'),
  createdAt:  timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt:  timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
}, (t) => [
  unique().on(t.bankId, t.format, t.version),
])

// ---- Record Types ----

export const recordTypes = pgTable('record_types', {
  id:                       uuid('id').primaryKey().defaultRandom(),
  layoutId:                 uuid('layout_id').notNull().references(() => cnabLayouts.id, { onDelete: 'cascade' }),
  code:                     varchar('code', { length: 30 }).notNull(),
  description:              varchar('description', { length: 200 }).notNull(),
  category:                 varchar('category', { length: 10 }).notNull(),   // 'HEADER' | 'DETAIL' | 'TRAILER'
  identifierStart:          smallint('identifier_start').notNull(),
  identifierEnd:            smallint('identifier_end').notNull(),
  identifierValue:          varchar('identifier_value', { length: 20 }).notNull(),
  secondaryIdentifierStart: smallint('secondary_identifier_start'),
  secondaryIdentifierEnd:   smallint('secondary_identifier_end'),
  secondaryIdentifierValue: varchar('secondary_identifier_value', { length: 20 }),
  sortOrder:                smallint('sort_order').notNull(),
  createdAt:                timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (t) => [
  unique().on(t.layoutId, t.code),
])

// ---- Field Definitions ----

export const fieldDefinitions = pgTable('field_definitions', {
  id:              uuid('id').primaryKey().defaultRandom(),
  recordTypeId:    uuid('record_type_id').notNull().references(() => recordTypes.id, { onDelete: 'cascade' }),
  name:            varchar('name', { length: 100 }).notNull(),
  label:           varchar('label', { length: 200 }).notNull(),
  description:     text('description'),
  startPosition:   smallint('start_position').notNull(),
  endPosition:     smallint('end_position').notNull(),
  length:          smallint('length').notNull(),
  dataType:        varchar('data_type', { length: 20 }).notNull(),
  formatMask:      varchar('format_mask', { length: 50 }),
  decimalPlaces:   smallint('decimal_places').default(0).notNull(),
  isRequired:      boolean('is_required').default(true).notNull(),
  isFiller:        boolean('is_filler').default(false).notNull(),
  allowedValues:   text('allowed_values').array(),
  validationRules: jsonb('validation_rules'),
  sortOrder:       smallint('sort_order').notNull(),
  createdAt:       timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
})

// ---- Relations ----

export const banksRelations = relations(banks, ({ many }) => ({
  layouts: many(cnabLayouts),
}))

export const cnabLayoutsRelations = relations(cnabLayouts, ({ one, many }) => ({
  bank:        one(banks, { fields: [cnabLayouts.bankId], references: [banks.id] }),
  recordTypes: many(recordTypes),
}))

export const recordTypesRelations = relations(recordTypes, ({ one, many }) => ({
  layout:           one(cnabLayouts, { fields: [recordTypes.layoutId], references: [cnabLayouts.id] }),
  fieldDefinitions: many(fieldDefinitions),
}))

export const fieldDefinitionsRelations = relations(fieldDefinitions, ({ one }) => ({
  recordType: one(recordTypes, { fields: [fieldDefinitions.recordTypeId], references: [recordTypes.id] }),
}))

// ---- Inferred types ----

export type Bank           = typeof banks.$inferSelect
export type NewBank        = typeof banks.$inferInsert
export type CnabLayout     = typeof cnabLayouts.$inferSelect
export type NewCnabLayout  = typeof cnabLayouts.$inferInsert
export type RecordType     = typeof recordTypes.$inferSelect
export type NewRecordType  = typeof recordTypes.$inferInsert
export type FieldDef       = typeof fieldDefinitions.$inferSelect
export type NewFieldDef    = typeof fieldDefinitions.$inferInsert
