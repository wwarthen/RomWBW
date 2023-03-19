
; -----------------------------------------------------------------------------
; Copyright 2021 Dimitri Theulings
;
; This file is part of Tasty Basic.
;
; Tasty Basic is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; Tasty Basic is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with Tasty Basic.  If not, see <https://www.gnu.org/licenses/>.
; -----------------------------------------------------------------------------
; Tasty Basic is derived from earlier works by Li-Chen Wang, Peter Rauskolb,
; and Doug Gabbard. Refer to the source code repository for details
; <https://github.com/dimitrit/tastybasic/>.
; -----------------------------------------------------------------------------

USRPTR_OFFSET			.equ 09feh
INTERNAL_OFFSET			.equ 0c00h
TEXTEND_OFFSET			.equ 07dffh
STACK_OFFSET			.equ 07fffh

tty_data			.equ 7ch
tty_status			.equ 7dh
rx_full				.equ 1
tx_empty			.equ 0

putchar:
				call uart_tx_ready			; see if transmit is available
				out (tty_data),a			; and send it
				ret
uart_tx_ready:
				push af
uart_tx_ready_loop:
				in a,(tty_status)
				bit tx_empty,a
				jp z,uart_tx_ready_loop
				pop af
				ret
haschar:
				in a,(tty_status)			; check if character available
				bit rx_full,a
				ret

getchar:
				in a,(tty_data)				; get the character
				ret
