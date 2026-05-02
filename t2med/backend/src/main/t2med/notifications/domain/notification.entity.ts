export class Notification {
  userId: string;
  type: 'medication_reminder' | 'low_stock_alert' | 'emergency_contact';
  title: string;
  body: string;
  data?: Record<string, string>;
  createdAt?: any;
}