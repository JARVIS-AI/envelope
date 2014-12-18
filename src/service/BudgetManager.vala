/* Copyright 2014 Nicolas Laplante
*
* This file is part of envelope.
*
* envelope is free software: you can redistribute it
* and/or modify it under the terms of the GNU General Public License as
* published by the Free Software Foundation, either version 3 of the
* License, or (at your option) any later version.
*
* envelope is distributed in the hope that it will be
* useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along
* with envelope. If not, see http://www.gnu.org/licenses/.
*/

using Gee;
using Envelope.DB;

namespace Envelope.Service {

    public struct BudgetState {
        DateTime from;
        DateTime to;
        double inflow;
        double outflow;
    }

    public class BudgetManager {

        private static BudgetManager budget_manager_instance = null;

        public static new unowned BudgetManager get_default () {
            if (budget_manager_instance == null) {
                budget_manager_instance = new BudgetManager ();
            }

            return budget_manager_instance;
        }

        private BudgetManager () {
            budget_manager_instance = this;
        }

        public ArrayList<Transaction> get_current_transactions () throws ServiceError {

            try {
                return DatabaseManager.get_default ().get_current_transactions ();
            }
            catch (SQLHeavy.Error err) {
                throw new ServiceError.DATABASE_ERROR (err.message);
            }
        }

        public BudgetState compute_current_state () throws ServiceError {

            var state = BudgetState ();

            state.inflow = 0d;
            state.outflow = 0d;

            compute_dates (out state.from, out state.to);

            foreach (Transaction t in get_current_transactions ()) {

                switch (t.direction) {
                    case Transaction.Direction.INCOMING:
                        state.inflow += t.amount;
                        break;

                    case Transaction.Direction.OUTGOING:
                        state.outflow += t.amount;
                        break;

                    default:
                        assert_not_reached ();
                }
            }

            debug ("budget state: inflow: %s, outflow: %s".printf (
                Envelope.Util.format_currency (state.inflow),
                Envelope.Util.format_currency (state.outflow)
                ));

            return state;
        }

        private void compute_dates (out DateTime from, out DateTime to) {

            var now = new DateTime.now_local ();

            from = new DateTime.local (now.get_year (), now.get_month (), 1, 0, 0, 0);
            to = new DateTime.local (now.get_year (), now.get_month (), 1, 0, 0, 0);

            // compute last day
            to = to.add_months (1).add_days (-1);
        }
    }

}